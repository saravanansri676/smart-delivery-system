package com.example.demo.service;


import com.example.demo.model.Package;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class TSPService {

    // Haversine formula - real distance between two coordinates in km
    public double calculateDistance(double lat1, double lon1,
                                    double lat2, double lon2) {
        final int R = 6371;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLon = Math.toRadians(lon2 - lon1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
                + Math.cos(Math.toRadians(lat1))
                * Math.cos(Math.toRadians(lat2))
                * Math.sin(dLon / 2) * Math.sin(dLon / 2);
        double c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    }

    // Nearest Neighbor TSP Algorithm
    public List<Package> optimizeRoute(List<Package> packages,
                                       double startLat, double startLon) {
        List<Package> unvisited = new ArrayList<>(packages);
        List<Package> route = new ArrayList<>();

        double currentLat = startLat;
        double currentLon = startLon;

        while (!unvisited.isEmpty()) {
            Package nearest = null;
            double minDistance = Double.MAX_VALUE;

            for (Package pkg : unvisited) {
                double dist = calculateDistance(
                        currentLat, currentLon,
                        pkg.getLatitude(), pkg.getLongitude()
                );
                if (dist < minDistance) {
                    minDistance = dist;
                    nearest = pkg;
                }
            }

            route.add(nearest);
            currentLat = nearest.getLatitude();
            currentLon = nearest.getLongitude();
            unvisited.remove(nearest);
        }

        return route;
    }

    // Priority Score - lower score = deliver first
    // Considers deadline urgency
    public int calculatePriority(String deadline) {
        try {
            String[] parts = deadline.split(":");
            int hours = Integer.parseInt(parts[0]);
            int minutes = Integer.parseInt(parts[1]);
            return hours * 60 + minutes; // earlier deadline = lower score = higher priority
        } catch (Exception e) {
            return 999; // no deadline = lowest priority
        }
    }

    // Sort packages by priority first, then optimize route
    public List<Package> optimizeWithPriority(List<Package> packages,
                                              double startLat, double startLon) {
        // Separate urgent packages (deadline within 2 hours)
        List<Package> urgent = new ArrayList<>();
        List<Package> normal = new ArrayList<>();

        // Get current time in minutes
        java.time.LocalTime now = java.time.LocalTime.now();
        int currentMinutes = now.getHour() * 60 + now.getMinute();

        for (Package pkg : packages) {
            int deadlineMinutes = calculatePriority(pkg.getDeadline());
            if (deadlineMinutes - currentMinutes <= 120) { // within 2 hours
                urgent.add(pkg);
            } else {
                normal.add(pkg);
            }
        }

        // Optimize urgent first, then normal
        List<Package> result = new ArrayList<>();
        result.addAll(optimizeRoute(urgent, startLat, startLon));
        result.addAll(optimizeRoute(normal, startLat, startLon));

        return result;
    }
}
