package com.example.demo.service;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.List;

@Service
public class FuelService {

    // Convert fuel level to estimated litres
    public double convertFuelToLitres(String fuelLevel) {
        switch (fuelLevel.toUpperCase()) {
            case "FULL": return 40.0;
            case "MID":  return 20.0;
            case "LOW":  return 8.0;
            default:     return 0.0;
        }
    }

    // Average mileage km per litre
    private static final double MILEAGE = 12.0;

    // Minimum safe fuel reserve in litres
    private static final double FUEL_THRESHOLD = 3.0;

    // Check if driver has enough fuel
    public boolean hasSufficientFuel(Driver driver,
                                     List<Package> route,
                                     double startLat, double startLon,
                                     TSPService tspService) {
        double totalDistance = calculateTotalDistance(
                route, startLat, startLon, tspService);
        double fuelNeeded = totalDistance / MILEAGE;
        double fuelAvailable = convertFuelToLitres(driver.getFuelLevel());
        return fuelAvailable >= fuelNeeded + FUEL_THRESHOLD;
    }

    // Calculate total route distance
    public double calculateTotalDistance(List<Package> route,
                                         double startLat, double startLon,
                                         TSPService tspService) {
        double total = 0;
        double currentLat = startLat;
        double currentLon = startLon;

        for (Package pkg : route) {
            total += tspService.calculateDistance(
                    currentLat, currentLon,
                    pkg.getLatitude(), pkg.getLongitude()
            );
            currentLat = pkg.getLatitude();
            currentLon = pkg.getLongitude();
        }
        return total;
    }

    // Full fuel report
    public String getFuelReport(Driver driver,
                                List<Package> route,
                                double startLat, double startLon,
                                TSPService tspService) {
        double totalDistance = calculateTotalDistance(
                route, startLat, startLon, tspService);
        double fuelNeeded = totalDistance / MILEAGE;
        double fuelAvailable = convertFuelToLitres(driver.getFuelLevel());
        double fuelAfter = fuelAvailable - fuelNeeded;

        StringBuilder report = new StringBuilder();
        report.append(String.format(
                "Total route distance: %.2f km | ", totalDistance));
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
                        "Nearest station: %s (%s) - %.2f km away",
                        nearest.getName(),
                        nearest.getProvider(),
                        tspService.calculateDistance(
                                startLat, startLon,
                                nearest.getLatitude(),
                                nearest.getLongitude())));
            }
        } else {
            report.append(String.format(
                    "Sufficient fuel. Remaining after route: %.2f L",
                    fuelAfter));
        }

        return report.toString();
    }

    // Find nearest fuel station
    public FuelStation findNearestFuelStation(double currentLat,
                                              double currentLon,
                                              TSPService tspService) {
        List<FuelStation> stations = getChennaieFuelStations();
        FuelStation nearest = null;
        double minDist = Double.MAX_VALUE;

        for (FuelStation station : stations) {
            double dist = tspService.calculateDistance(
                    currentLat, currentLon,
                    station.getLatitude(), station.getLongitude()
            );
            if (dist < minDist) {
                minDist = dist;
                nearest = station;
            }
        }
        return nearest;
    }

    // Chennai fuel stations - IOC and BP
    private List<FuelStation> getChennaieFuelStations() {
        List<FuelStation> stations = new ArrayList<>();

        stations.add(new FuelStation(
                "IOC Adyar", "Indian Oil", 13.0067, 80.2575));
        stations.add(new FuelStation(
                "IOC Anna Nagar", "Indian Oil", 13.0878, 80.2087));
        stations.add(new FuelStation(
                "IOC Tambaram", "Indian Oil", 12.9249, 80.1000));
        stations.add(new FuelStation(
                "IOC Guindy", "Indian Oil", 13.0100, 80.2200));
        stations.add(new FuelStation(
                "BP T Nagar", "Bharat Petroleum", 13.0418, 80.2341));
        stations.add(new FuelStation(
                "BP Velachery", "Bharat Petroleum", 12.9815, 80.2180));
        stations.add(new FuelStation(
                "BP Sholinganallur", "Bharat Petroleum", 12.9010, 80.2279));
        stations.add(new FuelStation(
                "BP Perungudi", "Bharat Petroleum", 12.9716, 80.2450));

        return stations;
    }

    // Fuel Station inner class
    public static class FuelStation {
        private String name;
        private String provider;
        private double latitude;
        private double longitude;

        public FuelStation(String name, String provider,
                           double latitude, double longitude) {
            this.name = name;
            this.provider = provider;
            this.latitude = latitude;
            this.longitude = longitude;
        }

        public String getName() { return name; }
        public String getProvider() { return provider; }
        public double getLatitude() { return latitude; }
        public double getLongitude() { return longitude; }
    }
}
