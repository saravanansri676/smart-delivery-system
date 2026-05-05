package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import com.example.demo.repository.DriverRepository;
import com.example.demo.repository.PackageRepository;
import com.example.demo.service.NotificationService;
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

    @Autowired
    private NotificationService notificationService;

    private static final DateTimeFormatter FMT =
            DateTimeFormatter.ofPattern(
                    "yyyy-MM-dd HH:mm");

    // Driver deviated
    @GetMapping("/deviation/{driverId}")
    public List<Package> handleDeviation(
            @PathVariable String driverId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {
        return rerouteService.recalculateRoute(
                driverId, currentLat, currentLon,
                "DRIVER_DEVIATION");
    }

    // New package mid-delivery
    @PostMapping("/add-package/{driverId}")
    public List<Package> addPackageMidDelivery(
            @PathVariable String driverId,
            @RequestParam String packageId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {
        return rerouteService.addPackageAndReroute(
                driverId, packageId,
                currentLat, currentLon);
    }

    // Traffic reroute
    @GetMapping("/traffic/{driverId}")
    public List<Package> rerouteForTraffic(
            @PathVariable String driverId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {
        return rerouteService.recalculateRoute(
                driverId, currentLat, currentLon,
                "TRAFFIC_CHANGE");
    }

    // Remaining stops
    @GetMapping("/remaining/{driverId}")
    public List<Package> getRemainingStops(
            @PathVariable String driverId) {
        return rerouteService
                .getRemainingPackages(driverId);
    }

    // ── Mark delivered + update stats + notify ───────────────
    @PutMapping("/delivered/{packageId}")
    public String markDeliveredAndGetNext(
            @PathVariable String packageId,
            @RequestParam String driverId,
            @RequestParam double currentLat,
            @RequestParam double currentLon) {

        Package pkg = packageRepository
                .findById(packageId).orElse(null);
        if (pkg == null) return "Package not found";

        Driver driver = driverRepository
                .findById(driverId).orElse(null);
        if (driver == null) return "Driver not found";

        // Mark delivered
        pkg.setStatus("DELIVERED");
        packageRepository.save(pkg);

        // Update packagesDelivered count
        driver.setPackagesDelivered(
                driver.getPackagesDelivered() + 1);

        // Recalculate rating
        double deliveryScore =
                calculateDeliveryScore(pkg);
        int totalDelivered =
                driver.getPackagesDelivered();
        double currentRating =
                driver.getAverageRating();

        double newRating =
                ((currentRating * (totalDelivered - 1))
                        + deliveryScore)
                        / totalDelivered;
        newRating = Math.round(newRating * 10.0) / 10.0;
        newRating = Math.max(0.0,
                Math.min(5.0, newRating));
        driver.setAverageRating(newRating);
        driverRepository.save(driver);

        // Check remaining
        List<Package> remaining =
                rerouteService.getRemainingPackages(
                        driverId);

        if (remaining.isEmpty()) {
            // All done — set AVAILABLE
            driver.setStatus("AVAILABLE");
            driverRepository.save(driver);

            // Notify driver
            notificationService
                    .notifyAllDelivered(driverId);

            return "ALL_DELIVERED";
        }

        // ── Check deadline warnings for remaining ────────────
        // If any remaining package deadline is within
        // 60 minutes → send warning notification
        LocalDateTime now = LocalDateTime.now();
        for (Package rem : remaining) {
            try {
                String deadlineDateStr =
                        rem.getDeadlineDate();
                if (deadlineDateStr == null
                        || deadlineDateStr.isEmpty())
                    continue;

                LocalDateTime deadline =
                        LocalDateTime.parse(
                                deadlineDateStr.trim(),
                                FMT);

                long minutesLeft =
                        java.time.Duration
                                .between(now, deadline)
                                .toMinutes();

                // Within 60 mins and not yet past
                if (minutesLeft > 0
                        && minutesLeft <= 60) {
                    notificationService
                            .notifyDeadlineWarning(
                                    driverId,
                                    rem.getPackageName(),
                                    rem.getDeadline());
                    // Only warn once per delivery cycle
                    break;
                }
            } catch (DateTimeParseException ignored) {}
        }

        // Return next stop info
        List<Package> nextRoute =
                rerouteService.recalculateRoute(
                        driverId, currentLat, currentLon,
                        "PACKAGE_DELIVERED");

        return "NEXT:"
                + nextRoute.get(0).getAddress()
                + "|"
                + nextRoute.get(0).getPackageName()
                + "|"
                + nextRoute.get(0).getDeadline();
    }

    // ── Delivery score based on deadline ─────────────────────
    private double calculateDeliveryScore(Package pkg) {
        try {
            String deadlineDateStr =
                    pkg.getDeadlineDate();

            if (deadlineDateStr == null
                    || deadlineDateStr.trim().isEmpty()) {
                String deadlineTime = pkg.getDeadline();
                if (deadlineTime == null
                        || deadlineTime.trim().isEmpty())
                    return 5.0;
                deadlineDateStr =
                        LocalDateTime.now().format(
                                DateTimeFormatter
                                        .ofPattern(
                                                "yyyy-MM-dd"))
                                + " "
                                + deadlineTime.trim();
            }

            LocalDateTime deadline =
                    LocalDateTime.parse(
                            deadlineDateStr.trim(), FMT);
            LocalDateTime now = LocalDateTime.now();

            if (!now.isAfter(deadline)) return 5.0;

            long minutesLate =
                    java.time.Duration
                            .between(deadline, now)
                            .toMinutes();

            if (minutesLate <= 30) return 4.0;
            if (minutesLate <= 60) return 3.5;
            if (minutesLate <= 120) return 3.0;
            return 2.0;

        } catch (DateTimeParseException e) {
            return 5.0;
        }
    }
}