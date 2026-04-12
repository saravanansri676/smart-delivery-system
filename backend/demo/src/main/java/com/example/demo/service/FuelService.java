package com.example.demo.service;

import com.example.demo.model.Driver;
import com.example.demo.model.FuelStation;
import com.example.demo.model.Package;
import com.example.demo.repository.FuelStationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class FuelService {

    // FuelStationRepository is a proper @Repository bean.
    @Autowired
    private FuelStationRepository fuelStationRepository;

    // ── Fuel level → estimated litres ──────────────────────
    public double convertFuelToLitres(String fuelLevel) {
        switch (fuelLevel.toUpperCase()) {
            case "FULL": return 40.0;
            case "MID":  return 20.0;
            case "LOW":  return 8.0;
            default:     return 0.0;
        }
    }

    private static final double MILEAGE = 12.0;
    private static final double FUEL_THRESHOLD = 3.0;

    // ── Check if driver has enough fuel ────────────────────
    public boolean hasSufficientFuel(
            Driver driver,
            List<Package> route,
            double startLat, double startLon,
            TSPService tspService) {

        double totalDistance = calculateTotalDistance(
                route, startLat, startLon, tspService);
        double fuelNeeded = totalDistance / MILEAGE;
        double fuelAvailable = convertFuelToLitres(
                driver.getFuelLevel());
        return fuelAvailable
                >= fuelNeeded + FUEL_THRESHOLD;
    }

    // ── Calculate total route distance ─────────────────────
    public double calculateTotalDistance(
            List<Package> route,
            double startLat, double startLon,
            TSPService tspService) {

        double total = 0;
        double currentLat = startLat;
        double currentLon = startLon;

        for (Package pkg : route) {
            total += tspService.calculateDistance(
                    currentLat, currentLon,
                    pkg.getLatitude(),
                    pkg.getLongitude());
            currentLat = pkg.getLatitude();
            currentLon = pkg.getLongitude();
        }
        return total;
    }

    // ── Full fuel report ───────────────────────────────────
    public String getFuelReport(
            Driver driver,
            List<Package> route,
            double startLat, double startLon,
            TSPService tspService) {

        double totalDistance = calculateTotalDistance(
                route, startLat, startLon, tspService);
        double fuelNeeded = totalDistance / MILEAGE;
        double fuelAvailable = convertFuelToLitres(
                driver.getFuelLevel());
        double fuelAfter = fuelAvailable - fuelNeeded;

        StringBuilder report = new StringBuilder();
        report.append(String.format(
                "Total route distance: %.2f km | ",
                totalDistance));
        report.append(String.format(
                "Fuel needed: %.2f L | ", fuelNeeded));
        report.append(String.format(
                "Fuel level: %s (~%.0f L) | ",
                driver.getFuelLevel(), fuelAvailable));

        if (fuelAfter < FUEL_THRESHOLD) {
            report.append("WARNING: Insufficient fuel! ");
            FuelStation nearest = findNearestFuelStation(
                    startLat, startLon, tspService);
            if (nearest != null) {
                report.append(String.format(
                        "Nearest station: %s (%s) "
                                + "- %.2f km away",
                        nearest.getName(),
                        nearest.getProvider(),
                        tspService.calculateDistance(
                                startLat, startLon,
                                nearest.getLatitude(),
                                nearest.getLongitude())));
            }
        } else {
            report.append(String.format(
                    "Sufficient fuel. Remaining after "
                            + "route: %.2f L", fuelAfter));
        }

        return report.toString();
    }

    // ── Find nearest fuel station ──────────────────────────
    // Reads from DB via injected repository (not static).
    // Falls back to in-memory defaults if DB is empty.
    public FuelStation findNearestFuelStation(
            double currentLat, double currentLon,
            TSPService tspService) {

        // ✅ Instance call — no static context issue
        List<FuelStation> stations =
                fuelStationRepository.findByActiveTrue();

        FuelStation nearest = null;
        double minDist = Double.MAX_VALUE;

        for (FuelStation station : stations) {
            double dist = tspService.calculateDistance(
                    currentLat, currentLon,
                    station.getLatitude(),
                    station.getLongitude());
            if (dist < minDist) {
                minDist = dist;
                nearest = station;
            }
        }
        return nearest;
    }


    // ── Helper to build a FuelStation object ───────────────
    private FuelStation build(String name, String provider,
                              double lat, double lon, String city) {
        FuelStation s = new FuelStation();
        s.setName(name);
        s.setProvider(provider);
        s.setLatitude(lat);
        s.setLongitude(lon);
        s.setCity(city);
        s.setActive(true);
        return s;
    }
}