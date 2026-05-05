package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.repository.DriverRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/drivers")
public class DriverController {

    @Autowired
    private DriverRepository driverRepository;

    // Add driver
    @PostMapping("/add")
    public String addDriver(
            @RequestBody Driver driver) {
        driver.setStatus("AVAILABLE");
        driverRepository.save(driver);
        return "Driver registered: "
                + driver.getDriverId();
    }

    // Get all drivers
    @GetMapping("/all")
    public List<Driver> getAllDrivers() {
        return driverRepository.findAll();
    }

    // Update status
    @PutMapping("/status/{id}")
    public String updateStatus(
            @PathVariable String id,
            @RequestParam String status) {
        return driverRepository.findById(id)
                .map(driver -> {
                    driver.setStatus(status);
                    driverRepository.save(driver);
                    return "Driver status updated to: "
                            + status;
                })
                .orElse("Driver not found");
    }

    // ── Update personal profile ─────────────────────────────
    // Saves: name, age, sex, mobileNumber
    @PutMapping("/profile/{driverId}")
    public String updateProfile(
            @PathVariable String driverId,
            @RequestBody Map<String, Object> body) {

        return driverRepository.findById(driverId)
                .map(driver -> {

                    if (body.containsKey("name"))
                        driver.setName(
                                (String) body.get("name"));

                    if (body.containsKey("age")) {
                        Object ageVal = body.get("age");
                        if (ageVal instanceof Integer)
                            driver.setAge(
                                    (Integer) ageVal);
                        else if (ageVal instanceof String) {
                            try {
                                driver.setAge(
                                        Integer.parseInt(
                                                (String) ageVal));
                            } catch (NumberFormatException
                                    ignored) {}
                        }
                    }

                    if (body.containsKey("sex"))
                        driver.setSex(
                                (String) body.get("sex"));

                    if (body.containsKey("mobileNumber"))
                        driver.setMobileNumber(
                                (String) body.get(
                                        "mobileNumber"));

                    driverRepository.save(driver);
                    return "Profile updated successfully";
                })
                .orElse("Driver not found");
    }

    // ── Update vehicle details ──────────────────────────────
    // Called when driver fills vehicle form
    // before starting deliveries.
    // Saves: vehicleType, vehicleNo,
    //        vehicleCapacity, fuelLevel
    // Also sets driver status to ON_DELIVERY
    // since they are starting their route.
    @PutMapping("/vehicle/{driverId}")
    public String updateVehicle(
            @PathVariable String driverId,
            @RequestBody Map<String, Object> body) {

        return driverRepository.findById(driverId)
                .map(driver -> {

                    if (body.containsKey("vehicleType"))
                        driver.setVehicleType(
                                (String) body.get(
                                        "vehicleType"));

                    if (body.containsKey("vehicleNo"))
                        driver.setVehicleNo(
                                (String) body.get(
                                        "vehicleNo"));

                    if (body.containsKey(
                            "vehicleCapacity")) {
                        Object cap = body.get(
                                "vehicleCapacity");
                        if (cap instanceof Number)
                            driver.setVehicleCapacity(
                                    ((Number) cap)
                                            .doubleValue());
                    }

                    if (body.containsKey("fuelLevel")) {
                        String fuel = ((String) body.get(
                                "fuelLevel"))
                                .toUpperCase();
                        // Only accept valid values
                        if (fuel.equals("FULL")
                                || fuel.equals("MID")
                                || fuel.equals("LOW"))
                            driver.setFuelLevel(fuel);
                    }

                    // Set ON_DELIVERY since driver
                    // is starting their route
                    driver.setStatus("ON_DELIVERY");

                    driverRepository.save(driver);
                    return "Vehicle updated successfully";
                })
                .orElse("Driver not found");
    }
}