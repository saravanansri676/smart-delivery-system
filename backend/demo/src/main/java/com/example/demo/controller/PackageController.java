package com.example.demo.controller;

import com.example.demo.model.Package;
import com.example.demo.repository.PackageRepository;
import com.example.demo.service.GeocodingService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/packages")
public class PackageController {

    @Autowired
    private PackageRepository packageRepository;

    @Autowired
    private GeocodingService geocodingService;

    // Add package
    @PostMapping("/add")
    public String addPackage(@RequestBody Package pkg) {
        // Always generate packageId on backend
        // Never trust client-side generated IDs
        pkg.setPackageId("PKG" + System.currentTimeMillis());

        // Auto-calculate coordinates from address
        if (pkg.getLatitude() == 0 && pkg.getLongitude() == 0) {
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

        // Return packageId so frontend can use it
        return "Package added: " + pkg.getPackageId();
    }

    // Get all packages
    @GetMapping("/all")
    public List<Package> getAllPackages() {
        return packageRepository.findAll();
    }

    // Get packages by status
    // Usage: GET /packages/by-status?status=IN_STORE
    @GetMapping("/by-status")
    public List<Package> getByStatus(
            @RequestParam String status) {
        return packageRepository.findByStatus(status);
    }

    // Get packages assigned to a specific driver
    // Usage: GET /packages/by-driver?driverId=DRV001
    @GetMapping("/by-driver")
    public List<Package> getByDriver(
            @RequestParam String driverId) {
        return packageRepository
                .findByAssignedDriverId(driverId);
    }

    // Get packages by driver AND status
    // Usage: GET /packages/by-driver-status
    //            ?driverId=DRV001&status=DELIVERED
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

    // Get single package
    @GetMapping("/{id}")
    public Package getPackage(@PathVariable String id) {
        return packageRepository.findById(id).orElse(null);
    }

    // Update status
    @PutMapping("/status/{id}")
    public String updateStatus(
            @PathVariable String id,
            @RequestParam String status) {
        return packageRepository.findById(id).map(pkg -> {
            pkg.setStatus(status);
            packageRepository.save(pkg);
            return "Status updated to: " + status;
        }).orElse("Package not found");
    }

    // Delete package
    @DeleteMapping("/{id}")
    public String deletePackage(@PathVariable String id) {
        packageRepository.deleteById(id);
        return "Package deleted: " + id;
    }
}