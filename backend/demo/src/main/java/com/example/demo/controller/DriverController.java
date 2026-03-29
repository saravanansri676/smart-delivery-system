package com.example.demo.controller;


import com.example.demo.model.Driver;
import com.example.demo.repository.DataStore;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/drivers")
public class DriverController {

    @Autowired
    private DataStore dataStore;

    // Register a driver
    @PostMapping("/add")
    public String addDriver(@RequestBody Driver driver) {
        driver.setStatus("AVAILABLE");
        dataStore.drivers.add(driver);
        return "Driver registered: " + driver.getDriverId();
    }

    // View all drivers
    @GetMapping("/all")
    public List<Driver> getAllDrivers() {
        return dataStore.drivers;
    }

    // Update driver status
    @PutMapping("/status/{id}")
    public String updateStatus(@PathVariable String id, @RequestParam String status) {
        for (Driver driver : dataStore.drivers) {
            if (driver.getDriverId().equals(id)) {
                driver.setStatus(status);
                return "Driver status updated to: " + status;
            }
        }
        return "Driver not found";
    }
}
