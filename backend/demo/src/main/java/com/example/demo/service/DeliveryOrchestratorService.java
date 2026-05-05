package com.example.demo.service;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import com.example.demo.repository.DriverBehaviorRepository;
import com.example.demo.repository.DriverRepository;
import com.example.demo.repository.PackageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Service
public class DeliveryOrchestratorService {

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private DriverBehaviorRepository behaviorRepository;

    @Autowired
    private TSPService tspService;

    @Autowired
    private TimeWindowService timeWindowService;

    @Autowired
    private FuelService fuelService;

    @Autowired
    private NotificationService notificationService;

    // ── MASTER METHOD ───────────────────────────────────────
    public Map<String, Object> generateFullDeliveryPlan(
            double startLat, double startLon) {

        Map<String, Object> plan = new HashMap<>();

        // Step 1: Get all unassigned packages
        List<Package> unassigned =
                packageRepository.findByStatus("IN_STORE");
        if (unassigned.isEmpty()) {
            plan.put("status", "No packages to deliver");
            return plan;
        }

        // Step 2: Get available drivers
        List<Driver> availableDrivers =
                driverRepository.findByStatus("AVAILABLE");
        if (availableDrivers.isEmpty()) {
            plan.put("status", "No available drivers");
            return plan;
        }

        // Step 3: Optimize full package list
        List<Package> optimized =
                tspService.optimizeWithPriority(
                        unassigned, startLat, startLon);

        // Step 4: Calculate how many drivers needed
        int driversNeeded = calculateDriversNeeded(
                optimized, startLat, startLon,
                availableDrivers.size());

        int driversToUse = Math.min(
                driversNeeded, availableDrivers.size());

        plan.put("totalPackages", unassigned.size());
        plan.put("availableDrivers",
                availableDrivers.size());
        plan.put("driversNeeded", driversNeeded);
        plan.put("driversAssigned", driversToUse);

        // Step 5: Distribute packages across N drivers
        List<List<Package>> distribution =
                distributePackages(optimized, driversToUse,
                        startLat, startLon);

        List<Map<String, Object>> driverPlans =
                new ArrayList<>();

        for (int i = 0; i < driversToUse; i++) {
            Driver driver = availableDrivers.get(i);
            List<Package> driverPackages =
                    distribution.get(i);

            if (driverPackages.isEmpty()) continue;

            // ✅ Set status to PENDING_ACCEPTANCE
            // instead of ASSIGNED directly.
            // Driver must accept before status moves
            // to ASSIGNED.
            for (Package pkg : driverPackages) {
                pkg.setStatus("PENDING_ACCEPTANCE");
                pkg.setAssignedDriverId(
                        driver.getDriverId());
                packageRepository.save(pkg);
            }

            // Driver stays AVAILABLE until they accept
            // (no longer set to ON_DELIVERY here)

            // Get behaviour-aware optimized route
            var behaviors = behaviorRepository
                    .findByDriverId(driver.getDriverId());
            List<Package> route = behaviors.isEmpty()
                    ? tspService.optimizeWithPriority(
                    driverPackages,
                    startLat, startLon)
                    : tspService.optimizeWithBehavior(
                    driverPackages,
                    startLat, startLon, behaviors);

            // Build driver plan
            Map<String, Object> driverPlan =
                    new HashMap<>();
            driverPlan.put("driverId",
                    driver.getDriverId());
            driverPlan.put("vehicleNo",
                    driver.getVehicleNo());
            driverPlan.put("packagesCount",
                    driverPackages.size());
            driverPlan.put("optimizedRoute", route);

            // Time window check
            String timeReport =
                    timeWindowService.getFeasibilityReport(
                            route, startLat, startLon,
                            tspService);
            driverPlan.put("timeWindowReport",
                    timeReport);

            // Fuel check
            String fuelReport =
                    fuelService.getFuelReport(
                            driver, route,
                            startLat, startLon,
                            tspService);
            driverPlan.put("fuelReport", fuelReport);

            // Deadline warnings
            List<String> deadlineWarnings =
                    timeWindowService.checkDeadlines(
                            route, startLat, startLon,
                            tspService);
            driverPlan.put("deadlineWarnings",
                    deadlineWarnings);

            driverPlans.add(driverPlan);

            // ✅ Send notification to driver
            notificationService.notifyPackageAssigned(
                    driver.getDriverId(),
                    driverPackages.size());
        }

        plan.put("driverPlans", driverPlans);
        plan.put("status",
                "Delivery plan generated successfully");
        return plan;
    }

    // ── Calculate drivers needed ────────────────────────────
    private int calculateDriversNeeded(
            List<Package> packages,
            double startLat, double startLon,
            int availableCount) {

        if (packages.isEmpty()) return 0;

        if (timeWindowService.fitsInMandatoryHours(
                packages, startLat, startLon, tspService))
            return 1;

        if (timeWindowService.fitsInOvertime(
                packages, startLat, startLon, tspService))
            return 1;

        double totalMins = timeWindowService
                .calculateTotalTime(packages,
                        startLat, startLon, tspService);

        double maxMinsPerDriver = 9 * 60;
        int driversNeeded = (int) Math.ceil(
                totalMins / maxMinsPerDriver);

        return Math.max(1,
                Math.min(driversNeeded, availableCount));
    }

    // ── Distribute packages across N drivers ────────────────
    private List<List<Package>> distributePackages(
            List<Package> packages, int numDrivers,
            double startLat, double startLon) {

        List<List<Package>> distribution =
                new ArrayList<>();
        for (int i = 0; i < numDrivers; i++) {
            distribution.add(new ArrayList<>());
        }

        if (numDrivers == 1) {
            distribution.get(0).addAll(packages);
            return distribution;
        }

        int total = packages.size();
        int baseSize = total / numDrivers;
        int remainder = total % numDrivers;
        int index = 0;

        for (int i = 0; i < numDrivers; i++) {
            int sliceSize =
                    baseSize + (i < remainder ? 1 : 0);
            for (int j = 0; j < sliceSize; j++) {
                if (index < total) {
                    distribution.get(i)
                            .add(packages.get(index++));
                }
            }
        }

        return distribution;
    }

    // ── Live status dashboard ───────────────────────────────
    public Map<String, Object> getLiveStatus() {
        Map<String, Object> status = new HashMap<>();

        long inStore = packageRepository
                .findByStatus("IN_STORE").size();
        long pending = packageRepository
                .findByStatus("PENDING_ACCEPTANCE").size();
        long assigned = packageRepository
                .findByStatus("ASSIGNED").size();
        long delivered = packageRepository
                .findByStatus("DELIVERED").size();
        long activeDrivers = driverRepository
                .findByStatus("ON_DELIVERY").size();
        long availableDrivers = driverRepository
                .findByStatus("AVAILABLE").size();

        status.put("packagesInStore", inStore);
        status.put("packagesPendingAcceptance", pending);
        status.put("packagesAssigned", assigned);
        status.put("packagesDelivered", delivered);
        status.put("activeDrivers", activeDrivers);
        status.put("availableDrivers", availableDrivers);
        status.put("totalPackages",
                inStore + pending + assigned + delivered);

        return status;
    }
}