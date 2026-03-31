package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import com.example.demo.repository.DriverRepository;
import com.example.demo.repository.PackageRepository;
import com.example.demo.service.TimeWindowService;
import com.example.demo.service.TSPService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/assign")
public class AssignmentController {

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private TimeWindowService timeWindowService;

    @Autowired
    private TSPService tspService;

    // Smart assignment - system decides single or multi driver
    @PostMapping("/smart")
    public String smartAssign(
            @RequestParam double startLat,
            @RequestParam double startLon) {

        List<Package> unassigned =
                packageRepository.findByStatus("IN_STORE");
        if (unassigned.isEmpty()) return "No packages to assign";

        List<Driver> available =
                driverRepository.findByStatus("AVAILABLE");
        if (available.isEmpty()) return "No available drivers";

        // Check if 1 driver can handle all packages
        List<Package> optimized = tspService.optimizeWithPriority(
                unassigned, startLat, startLon);

        if (timeWindowService.fitsInMandatoryHours(
                optimized, startLat, startLon, tspService)) {

            // 1 driver is enough
            Driver driver = available.get(0);
            for (Package pkg : unassigned) {
                pkg.setStatus("ASSIGNED");
                pkg.setAssignedDriverId(driver.getDriverId());
                packageRepository.save(pkg);
            }
            driver.setStatus("ON_DELIVERY");
            driverRepository.save(driver);
            return "All " + unassigned.size()
                    + " packages assigned to driver "
                    + driver.getDriverId()
                    + " (fits in mandatory hours)";

        } else if (available.size() >= 2) {

            // Split between 2 drivers
            List<List<Package>> split = timeWindowService.splitPackages(
                    unassigned, startLat, startLon, tspService);

            Driver driver1 = available.get(0);
            Driver driver2 = available.get(1);

            for (Package pkg : split.get(0)) {
                pkg.setStatus("ASSIGNED");
                pkg.setAssignedDriverId(driver1.getDriverId());
                packageRepository.save(pkg);
            }
            driver1.setStatus("ON_DELIVERY");
            driverRepository.save(driver1);

            for (Package pkg : split.get(1)) {
                pkg.setStatus("ASSIGNED");
                pkg.setAssignedDriverId(driver2.getDriverId());
                packageRepository.save(pkg);
            }
            driver2.setStatus("ON_DELIVERY");
            driverRepository.save(driver2);

            return "Packages split: "
                    + split.get(0).size() + " to driver "
                    + driver1.getDriverId() + ", "
                    + split.get(1).size() + " to driver "
                    + driver2.getDriverId();

        } else {
            // Only 1 driver available but too many packages
            // Check if overtime works
            if (timeWindowService.fitsInOvertime(
                    optimized, startLat, startLon, tspService)) {
                Driver driver = available.get(0);
                for (Package pkg : unassigned) {
                    pkg.setStatus("ASSIGNED");
                    pkg.setAssignedDriverId(driver.getDriverId());
                    packageRepository.save(pkg);
                }
                driver.setStatus("ON_DELIVERY");
                driverRepository.save(driver);
                return "WARNING: Assigned to driver "
                        + driver.getDriverId()
                        + " but requires overtime (before 6PM). "
                        + "Driver must accept overtime.";
            }
            return "WARNING: Too many packages for available drivers. "
                    + "Add more drivers or reduce packages.";
        }
    }

    // Manual assign to specific driver (keep old functionality)
    @PostMapping("/{driverId}")
    public String assignPackages(@PathVariable String driverId) {
        Driver driver = driverRepository.findById(driverId)
                .orElse(null);
        if (driver == null) return "Driver not found";

        List<Package> unassigned =
                packageRepository.findByStatus("IN_STORE");
        if (unassigned.isEmpty()) return "No packages to assign";

        for (Package pkg : unassigned) {
            pkg.setStatus("ASSIGNED");
            pkg.setAssignedDriverId(driverId);
            packageRepository.save(pkg);
        }
        driver.setStatus("ON_DELIVERY");
        driverRepository.save(driver);

        return "Assigned " + unassigned.size()
                + " packages to driver " + driverId;
    }

    // View packages assigned to driver
    @GetMapping("/{driverId}")
    public List<Package> getAssignedPackages(
            @PathVariable String driverId) {
        return packageRepository.findByAssignedDriverId(driverId);
    }
}