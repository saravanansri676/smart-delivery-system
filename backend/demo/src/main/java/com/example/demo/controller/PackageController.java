package com.example.demo.controller;

import com.example.demo.model.Package;
import com.example.demo.repository.PackageRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/packages")
public class PackageController {

    @Autowired
    private PackageRepository packageRepository;

    @PostMapping("/add")
    public String addPackage(@RequestBody Package pkg) {
        pkg.setStatus("IN_STORE");
        packageRepository.save(pkg);
        return "Package added: " + pkg.getPackageId();
    }

    @GetMapping("/all")
    public List<Package> getAllPackages() {
        return packageRepository.findAll();
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
}
