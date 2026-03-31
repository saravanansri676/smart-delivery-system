package com.example.demo.controller;

import com.example.demo.model.Package;
import com.example.demo.repository.PackageRepository;
import com.example.demo.service.RerouteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/reroute")
public class RerouteController {

    @Autowired
    private RerouteService rerouteService;

    @Autowired
    private PackageRepository packageRepository;

    // Driver deviated - recalculate from current position
    @GetMapping("/deviation/{driverId}")
    public List<Package> handleDeviation(
            @PathVariable String driverId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {

        return rerouteService.recalculateRoute(
                driverId, currentLat, currentLon, "DRIVER_DEVIATION");
    }

    // New package added mid-delivery - reroute
    @PostMapping("/add-package/{driverId}")
    public List<Package> addPackageMidDelivery(
            @PathVariable String driverId,
            @RequestParam String packageId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {

        List<Package> newRoute = rerouteService.addPackageAndReroute(
                driverId, packageId, currentLat, currentLon);

        if (newRoute == null) return null;
        return newRoute;
    }

    // Traffic change - force reroute
    @GetMapping("/traffic/{driverId}")
    public List<Package> rerouteForTraffic(
            @PathVariable String driverId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {

        return rerouteService.recalculateRoute(
                driverId, currentLat, currentLon, "TRAFFIC_CHANGE");
    }

    // Get remaining stops for driver
    @GetMapping("/remaining/{driverId}")
    public List<Package> getRemainingStops(
            @PathVariable String driverId) {
        return rerouteService.getRemainingPackages(driverId);
    }

    // Mark package delivered + get next stop
    @PutMapping("/delivered/{packageId}")
    public String markDeliveredAndGetNext(
            @PathVariable String packageId,
            @RequestParam String driverId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {

        // Mark as delivered
        Package pkg = packageRepository
                .findById(packageId).orElse(null);
        if (pkg == null) return "Package not found";

        pkg.setStatus("DELIVERED");
        packageRepository.save(pkg);

        // Get remaining stops
        List<Package> remaining =
                rerouteService.getRemainingPackages(driverId);

        if (remaining.isEmpty()) {
            return "All packages delivered! Great job! 🎉";
        }

        // Get next stop
        List<Package> nextRoute = rerouteService.recalculateRoute(
                driverId, currentLat, currentLon, "PACKAGE_DELIVERED");

        return "Delivered! Next stop: "
                + nextRoute.get(0).getAddress()
                + " (Package: " + nextRoute.get(0).getPackageName()
                + ", Deadline: " + nextRoute.get(0).getDeadline() + ")";
    }
}
