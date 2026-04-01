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

    @PostMapping("/add")
    public String addPackage(@RequestBody Package pkg) {
        // Auto-generate package ID if not provided
        if (pkg.getPackageId() == null
                || pkg.getPackageId().isEmpty()) {
            pkg.setPackageId("PKG" + System.currentTimeMillis());
        }

        // Auto-calculate coordinates from address
        if (pkg.getLatitude() == 0 && pkg.getLongitude() == 0) {
            double[] coords = geocodingService
                    .getCoordinates(pkg.getAddress());
            pkg.setLatitude(coords[0]);
            pkg.setLongitude(coords[1]);
        }

        pkg.setStatus("IN_STORE");
        packageRepository.save(pkg);
        return "Package added: " + pkg.getPackageId();
    }

    @GetMapping("/all")
    public List<Package> getAllPackages() {
        return packageRepository.findAll();
    }

    @GetMapping("/{id}")
    public Package getPackage(@PathVariable String id) {
        return packageRepository.findById(id).orElse(null);
    }

    @PutMapping("/status/{id}")
    public String updateStatus(@PathVariable String id,
                               @RequestParam String status) {
        return packageRepository.findById(id).map(pkg -> {
            pkg.setStatus(status);
            packageRepository.save(pkg);
            return "Status updated to: " + status;
        }).orElse("Package not found");
    }

    @DeleteMapping("/{id}")
    public String deletePackage(@PathVariable String id) {
        packageRepository.deleteById(id);
        return "Package deleted: " + id;
    }
}