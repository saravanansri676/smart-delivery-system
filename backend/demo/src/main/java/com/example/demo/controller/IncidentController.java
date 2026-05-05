package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.repository.DriverRepository;
import com.example.demo.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/incident")
public class IncidentController {

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private NotificationService notificationService;

    @PostMapping("/report/{driverId}")
    public String reportIncident(
            @PathVariable String driverId,
            @RequestParam String issue) {

        Driver reportingDriver = driverRepository
                .findById(driverId).orElse(null);
        if (reportingDriver == null)
            return "Driver not found";

        // Find nearest available driver to help
        List<Driver> availableDrivers =
                driverRepository.findByStatus("AVAILABLE");

        Driver nearestHelper = null;
        double minDistance = Double.MAX_VALUE;

        for (Driver d : availableDrivers) {
            if (!d.getDriverId().equals(driverId)) {
                double dist = calculateDistance(
                        reportingDriver.getCurrentLatitude(),
                        reportingDriver.getCurrentLongitude(),
                        d.getCurrentLatitude(),
                        d.getCurrentLongitude());
                if (dist < minDistance) {
                    minDistance = dist;
                    nearestHelper = d;
                }
            }
        }

        // ── Notify all ON_DELIVERY drivers ───────────────────
        // So other drivers on the road are aware
        List<Driver> onDeliveryDrivers =
                driverRepository.findByStatus("ON_DELIVERY");

        String reportingName =
                reportingDriver.getName() != null
                        && !reportingDriver.getName().isEmpty()
                        ? reportingDriver.getName()
                        : driverId;

        for (Driver d : onDeliveryDrivers) {
            // Don't notify the reporting driver themselves
            if (!d.getDriverId().equals(driverId)) {
                notificationService.notifyIncident(
                        d.getDriverId(),
                        reportingName,
                        driverId,
                        issue);
            }
        }

        // Also notify available drivers nearby
        for (Driver d : availableDrivers) {
            if (!d.getDriverId().equals(driverId)) {
                notificationService.notifyIncident(
                        d.getDriverId(),
                        reportingName,
                        driverId,
                        issue);
            }
        }

        if (nearestHelper == null) {
            return "Incident reported: " + issue
                    + ". No available drivers nearby.";
        }

        return "Incident reported: " + issue
                + ". Nearest helper: Driver "
                + nearestHelper.getDriverId()
                + " ("
                + String.format("%.2f", minDistance)
                + " km away)";
    }

    private double calculateDistance(
            double lat1, double lon1,
            double lat2, double lon2) {
        final int R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2)
                * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2)
                * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(
                Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}