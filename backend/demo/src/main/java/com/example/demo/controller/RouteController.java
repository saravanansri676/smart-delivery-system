package com.example.demo.controller;

import com.example.demo.model.Package;
import com.example.demo.repository.PackageRepository;
import com.example.demo.service.TSPService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/route")
public class RouteController {

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private TSPService tspService;

    // Get optimized route for a driver
    @GetMapping("/optimize/{driverId}")
    public List<Package> getOptimizedRoute(
            @PathVariable String driverId,
            @RequestParam double startLat,
            @RequestParam double startLon) {

        // Fetch from DB using JPA — not DataStore
        List<Package> assignedPackages =
                packageRepository
                        .findByAssignedDriverId(driverId)
                        .stream()
                        .filter(pkg -> !"DELIVERED"
                                .equals(pkg.getStatus()))
                        .collect(Collectors.toList());

        if (assignedPackages.isEmpty()) {
            return List.of();
        }

        return tspService.optimizeWithPriority(
                assignedPackages, startLat, startLon);
    }

    // Mark a package as delivered
    @PutMapping("/delivered/{packageId}")
    public String markDelivered(
            @PathVariable String packageId) {

        return packageRepository
                .findById(packageId)
                .map(pkg -> {
                    pkg.setStatus("DELIVERED");
                    packageRepository.save(pkg);
                    return "Package " + packageId
                            + " marked as delivered!";
                })
                .orElse("Package not found");
    }

    // Get total distance of optimized route
    @GetMapping("/distance/{driverId}")
    public String getTotalDistance(
            @PathVariable String driverId,
            @RequestParam double startLat,
            @RequestParam double startLon) {

        List<Package> assignedPackages =
                packageRepository
                        .findByAssignedDriverId(driverId)
                        .stream()
                        .filter(pkg -> !"DELIVERED"
                                .equals(pkg.getStatus()))
                        .collect(Collectors.toList());

        if (assignedPackages.isEmpty())
            return "No packages assigned";

        List<Package> optimized =
                tspService.optimizeWithPriority(
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

        return String.format(
                "Total optimized distance: %.2f km",
                totalDistance);
    }
}