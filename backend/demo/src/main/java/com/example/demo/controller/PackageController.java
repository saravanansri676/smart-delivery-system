package com.example.demo.controller;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import com.example.demo.repository.DriverRepository;
import com.example.demo.repository.PackageRepository;
import com.example.demo.service.GeocodingService;
import com.example.demo.service.NotificationService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/packages")
public class PackageController {

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private DriverRepository driverRepository;

    @Autowired
    private GeocodingService geocodingService;

    @Autowired
    private NotificationService notificationService;

    // ── Add package ─────────────────────────────────────────
    @PostMapping("/add")
    public String addPackage(@RequestBody Package pkg) {
        // Always generate packageId on backend
        pkg.setPackageId(
                "PKG" + System.currentTimeMillis());

        // Auto-geocode if no coords provided
        if (pkg.getLatitude() == 0
                && pkg.getLongitude() == 0) {
            double[] coords = geocodingService
                    .getCoordinates(pkg.getAddress());
            if (coords != null) {
                pkg.setLatitude(coords[0]);
                pkg.setLongitude(coords[1]);
            } else {
                return "Invalid address, please refine: "
                        + pkg.getAddress();
            }
        }

        pkg.setStatus("IN_STORE");
        packageRepository.save(pkg);
        return "Package added: " + pkg.getPackageId();
    }

    // ── Get all packages ────────────────────────────────────
    @GetMapping("/all")
    public List<Package> getAllPackages() {
        return packageRepository.findAll();
    }

    // ── Filter by status ────────────────────────────────────
    @GetMapping("/by-status")
    public List<Package> getByStatus(
            @RequestParam String status) {
        return packageRepository.findByStatus(status);
    }

    // ── Filter by driver ────────────────────────────────────
    @GetMapping("/by-driver")
    public List<Package> getByDriver(
            @RequestParam String driverId) {
        return packageRepository
                .findByAssignedDriverId(driverId);
    }

    // ── Filter by driver AND status ─────────────────────────
    @GetMapping("/by-driver-status")
    public List<Package> getByDriverAndStatus(
            @RequestParam String driverId,
            @RequestParam String status) {
        return packageRepository
                .findByAssignedDriverId(driverId)
                .stream()
                .filter(p -> status.equals(p.getStatus()))
                .toList();
    }

    // ── Get single package ──────────────────────────────────
    @GetMapping("/{id}")
    public Package getPackage(@PathVariable String id) {
        return packageRepository.findById(id)
                .orElse(null);
    }

    // ── Update status ───────────────────────────────────────
    @PutMapping("/status/{id}")
    public String updateStatus(
            @PathVariable String id,
            @RequestParam String status) {
        return packageRepository.findById(id)
                .map(pkg -> {
                    pkg.setStatus(status);
                    packageRepository.save(pkg);
                    return "Status updated to: " + status;
                })
                .orElse("Package not found");
    }

    // ── Driver accepts all pending packages ─────────────────
    // Changes PENDING_ACCEPTANCE → ASSIGNED for this driver
    // This is called when driver taps "Accept" button
    @PutMapping("/accept/{driverId}")
    public String acceptPackages(
            @PathVariable String driverId) {

        List<Package> pending = packageRepository
                .findByAssignedDriverId(driverId)
                .stream()
                .filter(p -> "PENDING_ACCEPTANCE"
                        .equals(p.getStatus()))
                .toList();

        if (pending.isEmpty())
            return "No pending packages to accept";

        pending.forEach(pkg -> {
            pkg.setStatus("ASSIGNED");
            packageRepository.save(pkg);
        });

        return "ACCEPTED:" + pending.size();
    }

    // ── Driver declines all pending packages ─────────────────
    // Returns packages to IN_STORE, unassigns driver,
    // decreases driver rating by 0.3 per decline
    @PutMapping("/decline/{driverId}")
    public String declinePackages(
            @PathVariable String driverId,
            @RequestBody Map<String, String> body) {

        String reason = body.getOrDefault(
                "reason", "No reason provided");

        List<Package> pending = packageRepository
                .findByAssignedDriverId(driverId)
                .stream()
                .filter(p -> "PENDING_ACCEPTANCE"
                        .equals(p.getStatus()))
                .toList();

        if (pending.isEmpty())
            return "No pending packages to decline";

        // Return packages to store
        pending.forEach(pkg -> {
            pkg.setStatus("IN_STORE");
            pkg.setAssignedDriverId(null);
            packageRepository.save(pkg);
        });

        // Set driver back to AVAILABLE
        driverRepository.findById(driverId)
                .ifPresent(driver -> {
                    driver.setStatus("AVAILABLE");

                    // Decrease rating by 0.3, min 0.0
                    double newRating = Math.max(0.0,
                            driver.getAverageRating()
                                    - 0.3);
                    // Round to 1 decimal
                    newRating = Math.round(
                            newRating * 10.0) / 10.0;
                    driver.setAverageRating(newRating);

                    driverRepository.save(driver);
                });

        return "DECLINED:" + pending.size()
                + ":" + reason;
    }

    // ── Delete package ──────────────────────────────────────
    @DeleteMapping("/{id}")
    public String deletePackage(
            @PathVariable String id) {
        packageRepository.deleteById(id);
        return "Package deleted: " + id;
    }
}