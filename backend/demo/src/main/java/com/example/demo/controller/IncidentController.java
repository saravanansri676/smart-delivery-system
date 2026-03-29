package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.repository.DataStore;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.HashMap;

@RestController
@RequestMapping("/incident")
public class IncidentController {

    @Autowired
    private DataStore dataStore;

    // Driver reports a problem
    @PostMapping("/report/{driverId}")
    public String reportIncident(@PathVariable String driverId,
                                 @RequestParam String issue) {

        // Check driver exists
        Driver reportingDriver = null;
        for (Driver d : dataStore.drivers) {
            if (d.getDriverId().equals(driverId)) {
                reportingDriver = d;
                break;
            }
        }

        if (reportingDriver == null) return "Driver not found";

        // Find nearest available driver to help
        Driver nearestHelper = null;
        double minDistance = Double.MAX_VALUE;

        for (Driver d : dataStore.drivers) {
            if (!d.getDriverId().equals(driverId)
                    && "AVAILABLE".equals(d.getStatus())) {

                double dist = calculateDistance(
                        reportingDriver.getCurrentLatitude(),
                        reportingDriver.getCurrentLongitude(),
                        d.getCurrentLatitude(),
                        d.getCurrentLongitude()
                );

                if (dist < minDistance) {
                    minDistance = dist;
                    nearestHelper = d;
                }
            }
        }

        if (nearestHelper == null) {
            return "Incident reported: " + issue +
                    ". No available drivers nearby to assist.";
        }

        return "Incident reported: " + issue +
                ". Nearest helper: Driver " + nearestHelper.getDriverId() +
                " (" + String.format("%.2f", minDistance) + " km away)";
    }

    // View all incidents (simple log)
    @GetMapping("/all")
    public List<Map<String, String>> getAllIncidents() {
        // Placeholder - will connect to DB in later phase
        List<Map<String, String>> incidents = new ArrayList<>();
        Map<String, String> sample = new HashMap<>();
        sample.put("status", "Incident log will be stored in DB in Phase 4");
        incidents.add(sample);
        return incidents;
    }

    // Haversine formula - calculates distance between two coordinates
    private double calculateDistance(double lat1, double lon1,
                                     double lat2, double lon2) {
        final int R = 6371; // Earth radius in km
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }
}
