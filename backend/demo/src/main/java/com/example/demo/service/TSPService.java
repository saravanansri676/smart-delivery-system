package com.example.demo.service;

import com.example.demo.model.DriverBehavior;
import com.example.demo.model.Package;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class TSPService {

    // Haversine formula
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

    // Basic Nearest Neighbor TSP
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

    // Priority score - earlier deadline = higher priority
    public int calculatePriority(String deadline) {
        try {
            String[] parts = deadline.split(":");
            int hours = Integer.parseInt(parts[0]);
            int minutes = Integer.parseInt(parts[1]);
            return hours * 60 + minutes;
        } catch (Exception e) {
            return 999;
        }
    }

    // Optimize with priority
    public List<Package> optimizeWithPriority(List<Package> packages,
                                              double startLat,
                                              double startLon) {
        List<Package> urgent = new ArrayList<>();
        List<Package> normal = new ArrayList<>();

        java.time.LocalTime now = java.time.LocalTime.now();
        int currentMinutes = now.getHour() * 60 + now.getMinute();

        for (Package pkg : packages) {
            int deadlineMinutes = calculatePriority(pkg.getDeadline());
            if (deadlineMinutes - currentMinutes <= 120) {
                urgent.add(pkg);
            } else {
                normal.add(pkg);
            }
        }

        List<Package> result = new ArrayList<>();
        result.addAll(optimizeRoute(urgent, startLat, startLon));
        result.addAll(optimizeRoute(normal, startLat, startLon));
        return result;
    }

    // NEW: Behavior-aware cost calculation
    // Adds penalty to roads driver historically avoids
    public double calculateCostWithBehavior(
            double fromLat, double fromLon,
            double toLat, double toLon,
            List<DriverBehavior> behaviors) {

        double baseCost = calculateDistance(
                fromLat, fromLon, toLat, toLon);

        // Check if this road segment is avoided by driver
        for (DriverBehavior behavior : behaviors) {
            double fromMatch = calculateDistance(
                    fromLat, fromLon,
                    behavior.getAvoidedFromLat(),
                    behavior.getAvoidedFromLon());
            double toMatch = calculateDistance(
                    toLat, toLon,
                    behavior.getAvoidedToLat(),
                    behavior.getAvoidedToLon());

            // If within 0.5km of an avoided road → add penalty
            if (fromMatch < 0.5 && toMatch < 0.5) {
                baseCost += behavior.getAvoidCount() * 2.0;
            }
        }

        return baseCost;
    }

    // NEW: Behavior-aware TSP
    public List<Package> optimizeWithBehavior(
            List<Package> packages,
            double startLat, double startLon,
            List<DriverBehavior> behaviors) {

        List<Package> unvisited = new ArrayList<>(packages);
        List<Package> route = new ArrayList<>();

        double currentLat = startLat;
        double currentLon = startLon;

        while (!unvisited.isEmpty()) {
            Package nearest = null;
            double minCost = Double.MAX_VALUE;

            for (Package pkg : unvisited) {
                double cost = calculateCostWithBehavior(
                        currentLat, currentLon,
                        pkg.getLatitude(), pkg.getLongitude(),
                        behaviors
                );
                if (cost < minCost) {
                    minCost = cost;
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
}