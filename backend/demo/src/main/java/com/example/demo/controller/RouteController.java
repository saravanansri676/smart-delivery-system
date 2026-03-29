package com.example.demo.controller;

import com.example.demo.model.Package;
import com.example.demo.repository.DataStore;
import com.example.demo.service.TSPService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/route")
public class RouteController {

    @Autowired
    private DataStore dataStore;

    @Autowired
    private TSPService tspService;

    // Get optimized route for a driver
    @GetMapping("/optimize/{driverId}")
    public List<Package> getOptimizedRoute(
            @PathVariable String driverId,
            @RequestParam double startLat,
            @RequestParam double startLon) {

        // Get packages assigned to this driver
        List<Package> assignedPackages = new ArrayList<>();
        for (Package pkg : dataStore.packages) {
            if (driverId.equals(pkg.getAssignedDriverId())
                    && !"DELIVERED".equals(pkg.getStatus())) {
                assignedPackages.add(pkg);
            }
        }

        if (assignedPackages.isEmpty()) {
            return new ArrayList<>();
        }

        // Run TSP optimization with priority
        return tspService.optimizeWithPriority(
                assignedPackages, startLat, startLon);
    }

    // Mark a package as delivered
    @PutMapping("/delivered/{packageId}")
    public String markDelivered(@PathVariable String packageId) {
        for (Package pkg : dataStore.packages) {
            if (pkg.getPackageId().equals(packageId)) {
                pkg.setStatus("DELIVERED");
                return "Package " + packageId + " marked as delivered!";
            }
        }
        return "Package not found";
    }

    // Get total distance of optimized route
    @GetMapping("/distance/{driverId}")
    public String getTotalDistance(
            @PathVariable String driverId,
            @RequestParam double startLat,
            @RequestParam double startLon) {

        List<Package> assignedPackages = new ArrayList<>();
        for (Package pkg : dataStore.packages) {
            if (driverId.equals(pkg.getAssignedDriverId())
                    && !"DELIVERED".equals(pkg.getStatus())) {
                assignedPackages.add(pkg);
            }
        }

        if (assignedPackages.isEmpty()) return "No packages assigned";

        List<Package> optimized = tspService.optimizeWithPriority(
                assignedPackages, startLat, startLon);

        double totalDistance = 0;
        double currentLat = startLat;
        double currentLon = startLon;

        for (Package pkg : optimized) {
            totalDistance += tspService.calculateDistance(
                    currentLat, currentLon,
                    pkg.getLatitude(), pkg.getLongitude()
            );
            currentLat = pkg.getLatitude();
            currentLon = pkg.getLongitude();
        }

        return String.format("Total optimized distance: %.2f km", totalDistance);
    }
}
