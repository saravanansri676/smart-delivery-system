package com.example.controller;

import com.example.demo.model.Package;
import com.example.demo.repository.DataStore;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/packages")
public class PackageController {

    @Autowired
    private DataStore dataStore;

    // Add a new package
    @PostMapping("/add")
    public String addPackage(@RequestBody Package pkg) {
        pkg.setStatus("IN_STORE");
        dataStore.packages.add(pkg);
        return "Package added: " + pkg.getPackageId();
    }

    // View all packages
    @GetMapping("/all")
    public List<Package> getAllPackages() {
        return dataStore.packages;
    }

    // Update package status
    @PutMapping("/status/{id}")
    public String updateStatus(@PathVariable String id, @RequestParam String status) {
        for (Package pkg : dataStore.packages) {
            if (pkg.getPackageId().equals(id)) {
                pkg.setStatus(status);
                return "Status updated to: " + status;
            }
        }
        return "Package not found";
    }
}
