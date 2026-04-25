package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import com.example.demo.repository.DriverRepository;
import com.example.demo.repository.PackageRepository;
import com.example.demo.service.RerouteService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;

@RestController
@RequestMapping("/reroute")
public class RerouteController {

    @Autowired
    private RerouteService rerouteService;

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private DriverRepository driverRepository;

    // Driver deviated - recalculate from current position
    @GetMapping("/deviation/{driverId}")
    public List<Package> handleDeviation(
            @PathVariable String driverId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {
        return rerouteService.recalculateRoute(
                driverId, currentLat, currentLon,
                "DRIVER_DEVIATION");
    }

    // New package added mid-delivery - reroute
    @PostMapping("/add-package/{driverId}")
    public List<Package> addPackageMidDelivery(
            @PathVariable String driverId,
            @RequestParam String packageId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {
        return rerouteService.addPackageAndReroute(
                driverId, packageId, currentLat, currentLon);
    }

    // Traffic change - force reroute
    @GetMapping("/traffic/{driverId}")
    public List<Package> rerouteForTraffic(
            @PathVariable String driverId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {
        return rerouteService.recalculateRoute(
                driverId, currentLat, currentLon,
                "TRAFFIC_CHANGE");
    }

    // Get remaining stops for driver
    @GetMapping("/remaining/{driverId}")
    public List<Package> getRemainingStops(
            @PathVariable String driverId) {
        return rerouteService.getRemainingPackages(driverId);
    }

    // ── Mark package delivered + update stats ────────────────
    @PutMapping("/delivered/{packageId}")
    public String markDeliveredAndGetNext(
            @PathVariable String packageId,
            @RequestParam String driverId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {

        // Find package
        Package pkg = packageRepository
                .findById(packageId).orElse(null);
        if (pkg == null) return "Package not found";

        // Find driver
        Driver driver = driverRepository
                .findById(driverId).orElse(null);
        if (driver == null) return "Driver not found";

        // Mark package as delivered
        pkg.setStatus("DELIVERED");
        packageRepository.save(pkg);

        // ── Update packagesDelivered count ───────────────────
        driver.setPackagesDelivered(
                driver.getPackagesDelivered() + 1);

        // ── Recalculate averageRating ────────────────────────
        // Rating logic:
        // Each delivery gets a score 0.0 – 5.0
        // Delivered on time (before deadline) → 5.0
        // Delivered late → score reduced by how late
        //   (max 2 point penalty for being very late)
        // averageRating = running average across all deliveries
        double deliveryScore = calculateDeliveryScore(pkg);

        int totalDelivered = driver.getPackagesDelivered();
        double currentRating = driver.getAverageRating();

        // Running average formula:
        // newAvg = ((oldAvg * (n-1)) + newScore) / n
        double newRating = ((currentRating * (totalDelivered - 1))
                + deliveryScore) / totalDelivered;

        // Round to 1 decimal, clamp between 0 and 5
        newRating = Math.round(newRating * 10.0) / 10.0;
        newRating = Math.max(0.0, Math.min(5.0, newRating));

        driver.setAverageRating(newRating);
        driverRepository.save(driver);

        // ── Check remaining packages ─────────────────────────
        List<Package> remaining =
                rerouteService.getRemainingPackages(driverId);

        if (remaining.isEmpty()) {
            // All delivered — set driver back to AVAILABLE
            driver.setStatus("AVAILABLE");
            driverRepository.save(driver);
            return "ALL_DELIVERED";
        }

        // Still packages left — return next stop info
        List<Package> nextRoute =
                rerouteService.recalculateRoute(
                        driverId, currentLat, currentLon,
                        "PACKAGE_DELIVERED");

        return "NEXT:"
                + nextRoute.get(0).getAddress()
                + "|" + nextRoute.get(0).getPackageName()
                + "|" + nextRoute.get(0).getDeadline();
    }

    // ── Calculate delivery score based on deadline ───────────
    // On time  → 5.0
    // Up to 30 mins late → 4.0
    // Up to 60 mins late → 3.5
    // Up to 120 mins late → 3.0
    // More than 120 mins late → 2.0 (minimum)
    private double calculateDeliveryScore(Package pkg) {
        try {
            String deadlineDateStr = pkg.getDeadlineDate();

            if (deadlineDateStr == null
                    || deadlineDateStr.trim().isEmpty()) {
                // No deadline date stored — use HH:mm only
                // Assume today's date
                String deadlineTime = pkg.getDeadline();
                if (deadlineTime == null
                        || deadlineTime.trim().isEmpty()) {
                    return 5.0; // No deadline = full score
                }
                deadlineDateStr = LocalDateTime.now()
                        .format(DateTimeFormatter
                                .ofPattern("yyyy-MM-dd"))
                        + " " + deadlineTime.trim();
            }

            LocalDateTime deadline = LocalDateTime.parse(
                    deadlineDateStr.trim(),
                    DateTimeFormatter.ofPattern(
                            "yyyy-MM-dd HH:mm"));

            LocalDateTime now = LocalDateTime.now();

            if (!now.isAfter(deadline)) {
                // Delivered on time
                return 5.0;
            }

            // How many minutes late?
            long minutesLate = java.time.Duration
                    .between(deadline, now).toMinutes();

            if (minutesLate <= 30) return 4.0;
            if (minutesLate <= 60) return 3.5;
            if (minutesLate <= 120) return 3.0;
            return 2.0; // Very late

        } catch (DateTimeParseException e) {
            // Cannot parse deadline — give full score
            return 5.0;
        }
    }
}