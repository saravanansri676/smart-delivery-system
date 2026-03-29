package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import com.example.demo.repository.DataStore;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;

@RestController
@RequestMapping("/assign")
public class AssignmentController {

    @Autowired
    private DataStore dataStore;

    // Assign packages to a driver
    @PostMapping("/{driverId}")
    public String assignPackages(@PathVariable String driverId) {

        // Find driver
        Driver targetDriver = null;
        for (Driver d : dataStore.drivers) {
            if (d.getDriverId().equals(driverId)) {
                targetDriver = d;
                break;
            }
        }

        if (targetDriver == null) return "Driver not found";

        // Find unassigned packages
        List<Package> toAssign = new ArrayList<>();
        for (Package pkg : dataStore.packages) {
            if ("IN_STORE".equals(pkg.getStatus())) {
                toAssign.add(pkg);
            }
        }

        if (toAssign.isEmpty()) return "No packages to assign";

        // Assign packages to driver
        for (Package pkg : toAssign) {
            pkg.setStatus("ASSIGNED");
            pkg.setAssignedDriverId(driverId);
        }

        targetDriver.setStatus("ON_DELIVERY");

        return "Assigned " + toAssign.size() + " packages to driver " + driverId;
    }

    // View packages assigned to a driver
    @GetMapping("/{driverId}")
    public List<Package> getAssignedPackages(@PathVariable String driverId) {
        List<Package> result = new ArrayList<>();
        for (Package pkg : dataStore.packages) {
            if (driverId.equals(pkg.getAssignedDriverId())) {
                result.add(pkg);
            }
        }
        return result;
    }
}