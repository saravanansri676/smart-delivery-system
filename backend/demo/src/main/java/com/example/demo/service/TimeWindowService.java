package com.example.demo.service;

import com.example.demo.model.Package;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.ArrayList;
import java.util.List;

@Service
public class TimeWindowService {

    // Fixed company working hours
    public static final LocalTime WORK_START =
            LocalTime.of(9, 0);
    public static final LocalTime WORK_END =
            LocalTime.of(16, 0);   // 4PM mandatory
    public static final LocalTime OVERTIME_END =
            LocalTime.of(18, 0);   // 6PM max

    // Average time per delivery in minutes
    private static final int TIME_PER_DELIVERY = 10;

    // Average speed km/h
    private static final double AVERAGE_SPEED = 30.0;

    // Formatter for deadlineDate field (yyyy-MM-dd HH:mm)
    private static final DateTimeFormatter DATE_TIME_FMT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");

    // ── Calculate total time needed ─────────────────────────
    public double calculateTotalTime(
            List<Package> route,
            double startLat, double startLon,
            TSPService tspService) {

        double totalDistance = 0;
        double currentLat = startLat;
        double currentLon = startLon;

        for (Package pkg : route) {
            totalDistance += tspService.calculateDistance(
                    currentLat, currentLon,
                    pkg.getLatitude(), pkg.getLongitude());
            currentLat = pkg.getLatitude();
            currentLon = pkg.getLongitude();
        }

        double travelMins =
                (totalDistance / AVERAGE_SPEED) * 60;
        double deliveryMins =
                route.size() * TIME_PER_DELIVERY;
        return travelMins + deliveryMins;
    }

    // ── Check if route fits in mandatory hours (9AM-4PM) ───
    public boolean fitsInMandatoryHours(
            List<Package> route,
            double startLat, double startLon,
            TSPService tspService) {

        double totalMins = calculateTotalTime(
                route, startLat, startLon, tspService);
        LocalTime estimatedEnd =
                WORK_START.plusMinutes((long) totalMins);
        return !estimatedEnd.isAfter(WORK_END);
    }

    // ── Check if route fits in overtime (9AM-6PM) ──────────
    public boolean fitsInOvertime(
            List<Package> route,
            double startLat, double startLon,
            TSPService tspService) {

        double totalMins = calculateTotalTime(
                route, startLat, startLon, tspService);
        LocalTime estimatedEnd =
                WORK_START.plusMinutes((long) totalMins);
        return !estimatedEnd.isAfter(OVERTIME_END);
    }

    // ── Split packages between two drivers ──────────────────
    public List<List<Package>> splitPackages(
            List<Package> allPackages,
            double startLat, double startLon,
            TSPService tspService) {

        List<Package> driver1 = new ArrayList<>();
        List<Package> driver2 = new ArrayList<>();

        List<Package> optimized =
                tspService.optimizeWithPriority(
                        allPackages, startLat, startLon);

        int half = optimized.size() / 2;
        for (int i = 0; i < optimized.size(); i++) {
            if (i < half) driver1.add(optimized.get(i));
            else driver2.add(optimized.get(i));
        }

        List<List<Package>> split = new ArrayList<>();
        split.add(driver1);
        split.add(driver2);
        return split;
    }

    // ── Full feasibility report ─────────────────────────────
    public String getFeasibilityReport(
            List<Package> route,
            double startLat, double startLon,
            TSPService tspService) {

        double totalMins = calculateTotalTime(
                route, startLat, startLon, tspService);
        LocalTime estimatedEnd =
                WORK_START.plusMinutes((long) totalMins);

        StringBuilder report = new StringBuilder();
        report.append(String.format(
                "Mandatory hours: %s - %s | ",
                WORK_START, WORK_END));
        report.append(String.format(
                "Packages: %d | ", route.size()));
        report.append(String.format(
                "Estimated finish: %s | ", estimatedEnd));
        report.append(String.format(
                "Total time needed: %.0f mins | ",
                totalMins));

        if (fitsInMandatoryHours(
                route, startLat, startLon, tspService)) {
            long freeTime = java.time.Duration
                    .between(estimatedEnd, WORK_END)
                    .toMinutes();
            report.append(String.format(
                    "STATUS: Fits in mandatory hours. "
                            + "%d mins to spare.", freeTime));

        } else if (fitsInOvertime(
                route, startLat, startLon, tspService)) {
            long overBy = java.time.Duration
                    .between(WORK_END, estimatedEnd)
                    .toMinutes();
            report.append(String.format(
                    "STATUS: Needs overtime by %d mins "
                            + "(within 6PM limit). "
                            + "Driver can optionally accept.",
                    overBy));
        } else {
            long overBy = java.time.Duration
                    .between(OVERTIME_END, estimatedEnd)
                    .toMinutes();
            report.append(String.format(
                    "STATUS: Exceeds even overtime by "
                            + "%d mins. MUST split packages "
                            + "to another driver.", overBy));
        }

        return report.toString();
    }

    // ── Check individual package deadlines ──────────────────
    // Issue 12 fixed:
    // Previously used pkg.getDeadline() which is HH:mm only.
    // A package due tomorrow at 10:00 and one due today
    // at 10:00 looked identical — wrong ordering and warnings.
    //
    // Now uses pkg.getDeadlineDate() (yyyy-MM-dd HH:mm)
    // for full date+time comparison so tomorrow's packages
    // are correctly treated as less urgent than today's.
    //
    // Falls back to HH:mm if deadlineDate is missing
    // (e.g. legacy data) so nothing breaks.
    public List<String> checkDeadlines(
            List<Package> route,
            double startLat, double startLon,
            TSPService tspService) {

        List<String> warnings = new ArrayList<>();

        double currentLat = startLat;
        double currentLon = startLon;

        // Estimated delivery starts at WORK_START today
        LocalDateTime currentDateTime =
                LocalDateTime.now()
                        .with(WORK_START);

        for (Package pkg : route) {
            double dist = tspService.calculateDistance(
                    currentLat, currentLon,
                    pkg.getLatitude(), pkg.getLongitude());

            double travelMins =
                    (dist / AVERAGE_SPEED) * 60;

            currentDateTime = currentDateTime
                    .plusMinutes((long) travelMins
                            + TIME_PER_DELIVERY);

            // ── Parse deadline ──────────────────────────
            LocalDateTime deadlineDateTime =
                    parseDeadline(pkg);

            if (deadlineDateTime == null) {
                // Could not parse — skip warning for this
                warnings.add("WARNING: Could not parse "
                        + "deadline for package "
                        + pkg.getPackageId()
                        + " (" + pkg.getPackageName()
                        + "). Please check deadlineDate "
                        + "format.");
            } else if (currentDateTime.isAfter(
                    deadlineDateTime)) {
                warnings.add(String.format(
                        "DEADLINE MISSED: %s (%s) - "
                                + "deadline %s but estimated "
                                + "arrival %s",
                        pkg.getPackageName(),
                        pkg.getPackageId(),
                        deadlineDateTime
                                .format(DATE_TIME_FMT),
                        currentDateTime
                                .format(DATE_TIME_FMT)));
            }

            currentLat = pkg.getLatitude();
            currentLon = pkg.getLongitude();
        }

        if (warnings.isEmpty()) {
            warnings.add("All deadlines achievable!");
        }
        return warnings;
    }

    // ── Parse deadline from package ─────────────────────────
    // Priority: deadlineDate (yyyy-MM-dd HH:mm)
    // Fallback: deadline (HH:mm) — assumes today's date
    private LocalDateTime parseDeadline(Package pkg) {

        // Try deadlineDate first (full date + time)
        String deadlineDate = pkg.getDeadlineDate();
        if (deadlineDate != null
                && !deadlineDate.trim().isEmpty()) {
            try {
                return LocalDateTime.parse(
                        deadlineDate.trim(), DATE_TIME_FMT);
            } catch (DateTimeParseException e) {
                // Fall through to HH:mm fallback
            }
        }

        // Fallback: HH:mm only — assumes today
        String deadlineTime = pkg.getDeadline();
        if (deadlineTime != null
                && !deadlineTime.trim().isEmpty()) {
            try {
                LocalTime time = LocalTime.parse(
                        deadlineTime.trim());
                // Combine with today's date
                return LocalDateTime.now().with(time);
            } catch (DateTimeParseException e) {
                return null;
            }
        }

        return null;
    }
}