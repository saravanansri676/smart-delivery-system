package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import com.example.demo.repository.DriverRepository;
import com.example.demo.repository.PackageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/assign")
public class AssignmentController {

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private DriverRepository driverRepository;

    @PostMapping("/{driverId}")
    public String assignPackages(@PathVariable String driverId) {

        Driver driver = driverRepository.findById(driverId)
                .orElse(null);
        if (driver == null) return "Driver not found";

        List<Package> unassigned = packageRepository.findByStatus("IN_STORE");
        if (unassigned.isEmpty()) return "No packages to assign";

        for (Package pkg : unassigned) {
            pkg.setStatus("ASSIGNED");
            pkg.setAssignedDriverId(driverId);
            packageRepository.save(pkg);
        }

        driver.setStatus("ON_DELIVERY");
        driverRepository.save(driver);

        return "Assigned " + unassigned.size() + " packages to driver " + driverId;
    }

    @GetMapping("/{driverId}")
    public List<Package> getAssignedPackages(@PathVariable String driverId) {
        return packageRepository.findByAssignedDriverId(driverId);
    }
}