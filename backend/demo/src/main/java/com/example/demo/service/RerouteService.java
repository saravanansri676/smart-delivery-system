package com.example.demo.service;

import com.example.demo.model.DriverBehavior;
import com.example.demo.model.Package;
import com.example.demo.repository.DriverBehaviorRepository;
import com.example.demo.repository.PackageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.stream.Collectors;

@Service
public class RerouteService {

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private DriverBehaviorRepository behaviorRepository;

    @Autowired
    private TSPService tspService;

    // Get remaining (undelivered) packages for driver
    public List<Package> getRemainingPackages(String driverId) {
        return packageRepository
                .findByAssignedDriverId(driverId)
                .stream()
                .filter(p -> !"DELIVERED".equals(p.getStatus()))
                .collect(Collectors.toList());
    }

    // Recalculate route from driver's current position
    // Called when:
    // 1. Driver deviates from route
    // 2. New package added mid-delivery
    // 3. Traffic/road condition changes
    public List<Package> recalculateRoute(
            String driverId,
            double currentLat,
            double currentLon,
            String reason) {

        List<Package> remaining = getRemainingPackages(driverId);

        if (remaining.isEmpty()) return remaining;

        // Get driver behavior for personalized rerouting
        List<DriverBehavior> behaviors =
                behaviorRepository.findByDriverId(driverId);

        System.out.println("Rerouting triggered for driver "
                + driverId + " | Reason: " + reason
                + " | Remaining stops: " + remaining.size());

        if (behaviors.isEmpty()) {
            // No behavior data → priority based rerouting
            return tspService.optimizeWithPriority(
                    remaining, currentLat, currentLon);
        }

        // Behavior aware rerouting
        return tspService.optimizeWithBehavior(
                remaining, currentLat, currentLon, behaviors);
    }

    // Add new package to driver mid-delivery and reroute
    public List<Package> addPackageAndReroute(
            String driverId,
            String newPackageId,
            double currentLat,
            double currentLon) {

        // Assign new package to driver
        Package newPkg = packageRepository
                .findById(newPackageId).orElse(null);

        if (newPkg == null) return null;

        newPkg.setAssignedDriverId(driverId);
        newPkg.setStatus("ASSIGNED");
        packageRepository.save(newPkg);

        // Recalculate route with new package included
        return recalculateRoute(
                driverId, currentLat, currentLon, "NEW_PACKAGE_ADDED");
    }
}
