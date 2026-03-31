package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import com.example.demo.repository.DriverRepository;
import com.example.demo.repository.PackageRepository;
import com.example.demo.service.FuelService;
import com.example.demo.service.TSPService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/fuel")
public class FuelController {

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private FuelService fuelService;

    @Autowired
    private TSPService tspService;

    // Full fuel report
    @GetMapping("/report/{driverId}")
    public String getFuelReport(
            @PathVariable String driverId,
            @RequestParam double startLat,
            @RequestParam double startLon) {

        Driver driver = driverRepository.findById(driverId)
                .orElse(null);
        if (driver == null) return "Driver not found";

        List<Package> packages =
                packageRepository.findByAssignedDriverId(driverId);
        if (packages.isEmpty())
            return "No packages assigned to driver";

        List<Package> route = tspService.optimizeWithPriority(
                packages, startLat, startLon);

        return fuelService.getFuelReport(
                driver, route, startLat, startLon, tspService);
    }

    // Quick fuel check
    @GetMapping("/check/{driverId}")
    public String checkFuel(
            @PathVariable String driverId,
            @RequestParam double startLat,
            @RequestParam double startLon) {

        Driver driver = driverRepository.findById(driverId)
                .orElse(null);
        if (driver == null) return "Driver not found";

        List<Package> packages =
                packageRepository.findByAssignedDriverId(driverId);

        List<Package> route = tspService.optimizeWithPriority(
                packages, startLat, startLon);

        boolean sufficient = fuelService.hasSufficientFuel(
                driver, route, startLat, startLon, tspService);

        if (sufficient) {
            return "Fuel sufficient for route";
        } else {
            FuelService.FuelStation nearest =
                    fuelService.findNearestFuelStation(
                            startLat, startLon, tspService);
            return "Fuel insufficient! Nearest station: "
                    + nearest.getName()
                    + " (" + nearest.getProvider() + ")";
        }
    }

    // Update fuel level - FULL, MID, LOW only
    @PutMapping("/update/{driverId}")
    public String updateFuel(
            @PathVariable String driverId,
            @RequestParam String fuelLevel) {

        String upper = fuelLevel.toUpperCase();
        if (!upper.equals("FULL") && !upper.equals("MID")
                && !upper.equals("LOW")) {
            return "Invalid fuel level. Use: FULL, MID, or LOW";
        }

        return driverRepository.findById(driverId).map(driver -> {
            driver.setFuelLevel(upper);
            driverRepository.save(driver);
            return "Fuel level updated to: " + upper + " for driver "
                    + driverId;
        }).orElse("Driver not found");
    }
}