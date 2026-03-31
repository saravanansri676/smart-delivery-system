package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.repository.DriverRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/drivers")
public class DriverController {

    @Autowired
    private DriverRepository driverRepository;

    @PostMapping("/add")
    public String addDriver(@RequestBody Driver driver) {
        driver.setStatus("AVAILABLE");
        driverRepository.save(driver);
        return "Driver registered: " + driver.getDriverId();
    }

    @GetMapping("/all")
    public List<Driver> getAllDrivers() {
        return driverRepository.findAll();
    }

    @PutMapping("/status/{id}")
    public String updateStatus(@PathVariable String id,
                               @RequestParam String status) {
        return driverRepository.findById(id).map(driver -> {
            driver.setStatus(status);
            driverRepository.save(driver);
            return "Driver status updated to: " + status;
        }).orElse("Driver not found");
    }
}