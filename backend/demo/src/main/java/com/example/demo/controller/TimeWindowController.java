package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import com.example.demo.repository.DriverRepository;
import com.example.demo.repository.PackageRepository;
import com.example.demo.service.TimeWindowService;
import com.example.demo.service.TSPService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/timewindow")
public class TimeWindowController {

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private TimeWindowService timeWindowService;

    @Autowired
    private TSPService tspService;

    // Check if driver's assigned packages fit in working hours
    @GetMapping("/check/{driverId}")
    public String checkFeasibility(
            @PathVariable String driverId,
            @RequestParam double startLat,
            @RequestParam double startLon) {

        Driver driver = driverRepository.findById(driverId)
                .orElse(null);
        if (driver == null) return "Driver not found";

        List<Package> packages =
                packageRepository.findByAssignedDriverId(driverId);
        if (packages.isEmpty()) return "No packages assigned";

        List<Package> route = tspService.optimizeWithPriority(
                packages, startLat, startLon);

        return timeWindowService.getFeasibilityReport(
                route, startLat, startLon, tspService);
    }

    // Check individual package deadlines
    @GetMapping("/deadlines/{driverId}")
    public List<String> checkDeadlines(
            @PathVariable String driverId,
            @RequestParam double startLat,
            @RequestParam double startLon) {

        List<Package> packages =
                packageRepository.findByAssignedDriverId(driverId);
        if (packages.isEmpty()) return List.of("No packages assigned");

        List<Package> route = tspService.optimizeWithPriority(
                packages, startLat, startLon);

        return timeWindowService.checkDeadlines(
                route, startLat, startLon, tspService);
    }
}
