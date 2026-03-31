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
import java.util.stream.Collectors;

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
    private RerouteService rerouteService;

    // MASTER METHOD - Full delivery plan for all drivers
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

        // Step 3: Smart assignment
        List<Package> optimized = tspService.optimizeWithPriority(
                unassigned, startLat, startLon);

        int driversNeeded = calculateDriversNeeded(
                optimized, startLat, startLon);
        int driversAvailable = availableDrivers.size();
        int driversToUse = Math.min(driversNeeded, driversAvailable);

        plan.put("totalPackages", unassigned.size());
        plan.put("availableDrivers", driversAvailable);
        plan.put("driversAssigned", driversToUse);

        // Step 4: Distribute packages across drivers
        List<List<Package>> distribution = distributePackages(
                optimized, driversToUse);

        List<Map<String, Object>> driverPlans = new ArrayList<>();

        for (int i = 0; i < driversToUse; i++) {
            Driver driver = availableDrivers.get(i);
            List<Package> driverPackages = distribution.get(i);

            // Assign packages to driver in DB
            for (Package pkg : driverPackages) {
                pkg.setStatus("ASSIGNED");
                pkg.setAssignedDriverId(driver.getDriverId());
                packageRepository.save(pkg);
            }
            driver.setStatus("ON_DELIVERY");
            driverRepository.save(driver);

            // Get behavior-aware optimized route
            var behaviors = behaviorRepository
                    .findByDriverId(driver.getDriverId());
            List<Package> route = behaviors.isEmpty()
                    ? tspService.optimizeWithPriority(
                    driverPackages, startLat, startLon)
                    : tspService.optimizeWithBehavior(
                    driverPackages, startLat, startLon, behaviors);

            // Build driver plan
            Map<String, Object> driverPlan = new HashMap<>();
            driverPlan.put("driverId", driver.getDriverId());
            driverPlan.put("vehicleNo", driver.getVehicleNo());
            driverPlan.put("packagesCount", driverPackages.size());
            driverPlan.put("optimizedRoute", route);

            // Time window check
            String timeReport = timeWindowService.getFeasibilityReport(
                    route, startLat, startLon, tspService);
            driverPlan.put("timeWindowReport", timeReport);

            // Fuel check
            String fuelReport = fuelService.getFuelReport(
                    driver, route, startLat, startLon, tspService);
            driverPlan.put("fuelReport", fuelReport);

            // Deadline check
            List<String> deadlineWarnings =
                    timeWindowService.checkDeadlines(
                            route, startLat, startLon, tspService);
            driverPlan.put("deadlineWarnings", deadlineWarnings);

            driverPlans.add(driverPlan);
        }

        plan.put("driverPlans", driverPlans);
        plan.put("status", "Delivery plan generated successfully");
        return plan;
    }

    // Calculate how many drivers needed
    private int calculateDriversNeeded(List<Package> packages,
                                       double startLat, double startLon) {
        if (timeWindowService.fitsInMandatoryHours(
                packages, startLat, startLon, tspService)) {
            return 1;
        } else if (timeWindowService.fitsInOvertime(
                packages, startLat, startLon, tspService)) {
            return 1; // overtime possible
        }
        return 2; // need to split
    }

    // Distribute packages evenly across drivers
    private List<List<Package>> distributePackages(
            List<Package> packages, int numDrivers) {
        List<List<Package>> distribution = new ArrayList<>();
        for (int i = 0; i < numDrivers; i++) {
            distribution.add(new ArrayList<>());
        }
        for (int i = 0; i < packages.size(); i++) {
            distribution.get(i % numDrivers).add(packages.get(i));
        }
        return distribution;
    }

    // Get live status of all deliveries
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
        status.put("totalPackages", inStore + assigned + delivered);

        return status;
    }
}
