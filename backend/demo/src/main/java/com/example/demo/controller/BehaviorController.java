package com.example.demo.controller;

import com.example.demo.model.DriverBehavior;
import com.example.demo.model.Package;
import com.example.demo.repository.DriverBehaviorRepository;
import com.example.demo.repository.DriverRepository;
import com.example.demo.repository.PackageRepository;
import com.example.demo.service.TSPService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/behavior")
public class BehaviorController {

    @Autowired
    private DriverBehaviorRepository behaviorRepository;

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private TSPService tspService;

    // Driver reports an avoided road
    @PostMapping("/avoid/{driverId}")
    public String reportAvoidedRoad(
            @PathVariable String driverId,
            @RequestParam double fromLat,
            @RequestParam double fromLon,
            @RequestParam double toLat,
            @RequestParam double toLon,
            @RequestParam String reason) {

        if (driverRepository.findById(driverId).isEmpty()) {
            return "Driver not found";
        }

        // Check if this road already reported
        List<DriverBehavior> existing =
                behaviorRepository.findByDriverId(driverId);

        for (DriverBehavior b : existing) {
            double fromMatch = tspService.calculateDistance(
                    fromLat, fromLon,
                    b.getAvoidedFromLat(), b.getAvoidedFromLon());
            double toMatch = tspService.calculateDistance(
                    toLat, toLon,
                    b.getAvoidedToLat(), b.getAvoidedToLon());

            // If same road reported again → increase avoid count
            if (fromMatch < 0.5 && toMatch < 0.5) {
                b.setAvoidCount(b.getAvoidCount() + 1);
                behaviorRepository.save(b);
                return "Avoid count updated to: "
                        + b.getAvoidCount()
                        + " for this road segment";
            }
        }

        // New avoided road
        DriverBehavior behavior = new DriverBehavior();
        behavior.setDriverId(driverId);
        behavior.setAvoidedFromLat(fromLat);
        behavior.setAvoidedFromLon(fromLon);
        behavior.setAvoidedToLat(toLat);
        behavior.setAvoidedToLon(toLon);
        behavior.setAvoidCount(1);
        behavior.setReason(reason);
        behaviorRepository.save(behavior);

        return "Avoided road recorded for driver " + driverId;
    }

    // Get personalized route using behavior
    @GetMapping("/route/{driverId}")
    public List<Package> getPersonalizedRoute(
            @PathVariable String driverId,
            @RequestParam double startLat,
            @RequestParam double startLon) {

        List<Package> packages =
                packageRepository.findByAssignedDriverId(driverId);

        if (packages.isEmpty()) return packages;

        List<DriverBehavior> behaviors =
                behaviorRepository.findByDriverId(driverId);

        if (behaviors.isEmpty()) {
            // No behavior data yet → use normal TSP
            return tspService.optimizeWithPriority(
                    packages, startLat, startLon);
        }

        // Use behavior-aware TSP
        return tspService.optimizeWithBehavior(
                packages, startLat, startLon, behaviors);
    }

    // View all behavior records for a driver
    @GetMapping("/history/{driverId}")
    public List<DriverBehavior> getBehaviorHistory(
            @PathVariable String driverId) {
        return behaviorRepository.findByDriverId(driverId);
    }

    // Clear behavior history for a driver
    @DeleteMapping("/clear/{driverId}")
    public String clearHistory(@PathVariable String driverId) {
        List<DriverBehavior> behaviors =
                behaviorRepository.findByDriverId(driverId);
        behaviorRepository.deleteAll(behaviors);
        return "Behavior history cleared for driver " + driverId;
    }
}
