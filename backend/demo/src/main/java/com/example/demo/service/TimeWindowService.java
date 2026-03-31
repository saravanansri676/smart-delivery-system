package com.example.demo.service;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import org.springframework.stereotype.Service;

import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Service
public class TimeWindowService {

    // Fixed company working hours
    public static final LocalTime WORK_START = LocalTime.of(9, 0);
    public static final LocalTime WORK_END = LocalTime.of(16, 0);   // 4PM mandatory
    public static final LocalTime OVERTIME_END = LocalTime.of(18, 0); // 6PM max

    // Average time per delivery in minutes
    private static final int TIME_PER_DELIVERY = 10;

    // Average speed km/h
    private static final double AVERAGE_SPEED = 30.0;

    // Calculate total time needed for a list of packages
    public double calculateTotalTime(List<Package> route,
                                     double startLat, double startLon,
                                     TSPService tspService) {
        double totalDistance = 0;
        double currentLat = startLat;
        double currentLon = startLon;

        for (Package pkg : route) {
            totalDistance += tspService.calculateDistance(
                    currentLat, currentLon,
                    pkg.getLatitude(), pkg.getLongitude()
            );
            currentLat = pkg.getLatitude();
            currentLon = pkg.getLongitude();
        }

        double travelMins = (totalDistance / AVERAGE_SPEED) * 60;
        double deliveryMins = route.size() * TIME_PER_DELIVERY;
        return travelMins + deliveryMins;
    }

    // Check if packages fit in mandatory hours (9AM-4PM)
    public boolean fitsInMandatoryHours(List<Package> route,
                                        double startLat, double startLon,
                                        TSPService tspService) {
        double totalMins = calculateTotalTime(
                route, startLat, startLon, tspService);
        LocalTime estimatedEnd = WORK_START.plusMinutes((long) totalMins);
        return !estimatedEnd.isAfter(WORK_END);
    }

    // Check if packages fit in overtime (9AM-6PM)
    public boolean fitsInOvertime(List<Package> route,
                                  double startLat, double startLon,
                                  TSPService tspService) {
        double totalMins = calculateTotalTime(
                route, startLat, startLon, tspService);
        LocalTime estimatedEnd = WORK_START.plusMinutes((long) totalMins);
        return !estimatedEnd.isAfter(OVERTIME_END);
    }

    // Split packages between two drivers smartly
    public List<List<Package>> splitPackages(List<Package> allPackages,
                                             double startLat, double startLon,
                                             TSPService tspService) {
        List<Package> driver1Packages = new ArrayList<>();
        List<Package> driver2Packages = new ArrayList<>();

        // Optimize full route first
        List<Package> optimized = tspService.optimizeWithPriority(
                allPackages, startLat, startLon);

        // Split: first half to driver1, second half to driver2
        int half = optimized.size() / 2;
        for (int i = 0; i < optimized.size(); i++) {
            if (i < half) {
                driver1Packages.add(optimized.get(i));
            } else {
                driver2Packages.add(optimized.get(i));
            }
        }

        List<List<Package>> split = new ArrayList<>();
        split.add(driver1Packages);
        split.add(driver2Packages);
        return split;
    }

    // Get full feasibility report
    public String getFeasibilityReport(List<Package> route,
                                       double startLat, double startLon,
                                       TSPService tspService) {
        double totalMins = calculateTotalTime(
                route, startLat, startLon, tspService);
        LocalTime estimatedEnd = WORK_START.plusMinutes((long) totalMins);

        StringBuilder report = new StringBuilder();
        report.append(String.format(
                "Mandatory hours: %s - %s | ", WORK_START, WORK_END));
        report.append(String.format(
                "Packages: %d | ", route.size()));
        report.append(String.format(
                "Estimated finish: %s | ", estimatedEnd));
        report.append(String.format(
                "Total time needed: %.0f mins | ", totalMins));

        if (fitsInMandatoryHours(route, startLat, startLon, tspService)) {
            long freeTime = java.time.Duration.between(
                    estimatedEnd, WORK_END).toMinutes();
            report.append(String.format(
                    "STATUS: Fits in mandatory hours. %d mins to spare.",
                    freeTime));
        } else if (fitsInOvertime(route, startLat, startLon, tspService)) {
            long overBy = java.time.Duration.between(
                    WORK_END, estimatedEnd).toMinutes();
            report.append(String.format(
                    "STATUS: Needs overtime by %d mins (within 6PM limit). " +
                            "Driver can optionally accept.", overBy));
        } else {
            long overBy = java.time.Duration.between(
                    OVERTIME_END, estimatedEnd).toMinutes();
            report.append(String.format(
                    "STATUS: Exceeds even overtime by %d mins. " +
                            "MUST split packages to another driver.", overBy));
        }

        return report.toString();
    }

    // Check individual deadlines
    public List<String> checkDeadlines(List<Package> route,
                                       double startLat, double startLon,
                                       TSPService tspService) {
        List<String> warnings = new ArrayList<>();
        double currentLat = startLat;
        double currentLon = startLon;
        LocalTime currentTime = WORK_START;

        for (Package pkg : route) {
            double dist = tspService.calculateDistance(
                    currentLat, currentLon,
                    pkg.getLatitude(), pkg.getLongitude()
            );
            double travelMins = (dist / AVERAGE_SPEED) * 60;
            currentTime = currentTime
                    .plusMinutes((long) travelMins + TIME_PER_DELIVERY);

            LocalTime deadline = LocalTime.parse(pkg.getDeadline());
            if (currentTime.isAfter(deadline)) {
                warnings.add(String.format(
                        "DEADLINE MISSED: %s (%s) - deadline %s " +
                                "but estimated arrival %s",
                        pkg.getPackageName(), pkg.getPackageId(),
                        deadline, currentTime));
            }

            currentLat = pkg.getLatitude();
            currentLon = pkg.getLongitude();
        }

        if (warnings.isEmpty()) {
            warnings.add("All deadlines achievable!");
        }
        return warnings;
    }
}
