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
        // Issue 16 fixed — no longer capped at 2
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

            // Assign packages to driver in DB
            for (Package pkg : driverPackages) {
                pkg.setStatus("ASSIGNED");
                pkg.setAssignedDriverId(
                        driver.getDriverId());
                packageRepository.save(pkg);
            }
            driver.setStatus("ON_DELIVERY");
            driverRepository.save(driver);

            // Get behaviour-aware optimized route
            var behaviors = behaviorRepository
                    .findByDriverId(driver.getDriverId());
            List<Package> route = behaviors.isEmpty()
                    ? tspService.optimizeWithPriority(
                    driverPackages, startLat, startLon)
                    : tspService.optimizeWithBehavior(
                    driverPackages, startLat,
                    startLon, behaviors);

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
            driverPlan.put("timeWindowReport", timeReport);

            // Fuel check
            String fuelReport = fuelService.getFuelReport(
                    driver, route, startLat, startLon,
                    tspService);
            driverPlan.put("fuelReport", fuelReport);

            // Deadline check
            List<String> deadlineWarnings =
                    timeWindowService.checkDeadlines(
                            route, startLat, startLon,
                            tspService);
            driverPlan.put("deadlineWarnings",
                    deadlineWarnings);

            driverPlans.add(driverPlan);
        }

        plan.put("driverPlans", driverPlans);
        plan.put("status",
                "Delivery plan generated successfully");
        return plan;
    }

    // ── Issue 16 fixed: Calculate drivers needed ────────────
    // Old logic: always returned 1 or 2 regardless of load.
    //
    // New logic:
    // 1. Check if 1 driver can handle all in mandatory hours
    // 2. If not, estimate time per driver and calculate
    //    how many are needed to finish within overtime (6PM)
    // 3. Cap at available drivers count
    //
    // Formula: driversNeeded = ceil(totalTime / maxTimePerDriver)
    // where maxTimePerDriver = overtime window in minutes (540)

    private int calculateDriversNeeded(
            List<Package> packages,
            double startLat, double startLon,
            int availableCount) {

        if (packages.isEmpty()) return 0;

        // Check if 1 driver fits in mandatory hours
        if (timeWindowService.fitsInMandatoryHours(
                packages, startLat, startLon, tspService)) {
            return 1;
        }

        // Check if 1 driver fits with overtime
        if (timeWindowService.fitsInOvertime(
                packages, startLat, startLon, tspService)) {
            return 1;
        }

        // Calculate total minutes needed for all packages
        double totalMins = timeWindowService
                .calculateTotalTime(
                        packages, startLat, startLon,
                        tspService);

        // Maximum minutes a single driver can work
        // from WORK_START (9AM) to OVERTIME_END (6PM) = 540 mins
        double maxMinsPerDriver = 9 * 60; // 540 minutes

        // How many drivers needed to finish within overtime
        int driversNeeded = (int) Math.ceil(
                totalMins / maxMinsPerDriver);

        // Always need at least 1
        // Never more than available
        return Math.max(1,
                Math.min(driversNeeded, availableCount));
    }

    // ── Issue 16 fixed: Distribute packages across N drivers ─
    // Old logic: simple round-robin (pkg i → driver i % n)
    // This splits the optimized route randomly,
    // breaking geographic clustering.
    //
    // New logic: slice the optimized route into N consecutive
    // segments so each driver gets a geographically grouped
    // set of stops — minimises total travel distance.
    //
    // Example: 12 packages, 3 drivers
    // Driver 1 → packages 1-4  (first cluster)
    // Driver 2 → packages 5-8  (middle cluster)
    // Driver 3 → packages 9-12 (last cluster)

    private List<List<Package>> distributePackages(
            List<Package> packages, int numDrivers,
            double startLat, double startLon) {

        List<List<Package>> distribution = new ArrayList<>();
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
            // Distribute remainder packages to first drivers
            // e.g. 13 packages, 3 drivers → 5, 4, 4
            int sliceSize = baseSize
                    + (i < remainder ? 1 : 0);

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
        long assigned = packageRepository
                .findByStatus("ASSIGNED").size();
        long delivered = packageRepository
                .findByStatus("DELIVERED").size();
        long activeDrivers = driverRepository
                .findByStatus("ON_DELIVERY").size();
        long availableDrivers = driverRepository
                .findByStatus("AVAILABLE").size();

        status.put("packagesInStore", inStore);
        status.put("packagesAssigned", assigned);
        status.put("packagesDelivered", delivered);
        status.put("activeDrivers", activeDrivers);
        status.put("availableDrivers", availableDrivers);
        status.put("totalPackages",
                inStore + assigned + delivered);

        return status;
    }
}