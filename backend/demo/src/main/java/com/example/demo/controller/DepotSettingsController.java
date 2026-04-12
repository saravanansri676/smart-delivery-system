package com.example.demo.controller;

import com.example.demo.model.DepotSettings;
import com.example.demo.repository.DepotSettingsRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Map;

@RestController
@RequestMapping("/depot")
public class DepotSettingsController {

    @Autowired
    private DepotSettingsRepository depotRepository;

    // ── Get depot settings for a manager ───────────────────
    @GetMapping("/{managerId}")
    public DepotSettings getDepot(
            @PathVariable String managerId) {
        return depotRepository.findById(managerId)
                .orElse(null);
    }

    // ── Save or update depot location ───────────────────────
    @PostMapping("/save")
    public String saveDepot(
            @RequestBody Map<String, Object> body) {

        String managerId = (String) body.get("managerId");
        if (managerId == null || managerId.isEmpty())
            return "Manager ID required";

        // Load existing or create new
        DepotSettings depot = depotRepository
                .findById(managerId)
                .orElse(new DepotSettings());

        depot.setManagerId(managerId);
        depot.setDepotName(
                (String) body.getOrDefault(
                        "depotName", "Main Warehouse"));
        depot.setLatitude(
                ((Number) body.get("latitude"))
                        .doubleValue());
        depot.setLongitude(
                ((Number) body.get("longitude"))
                        .doubleValue());
        depot.setAddress(
                (String) body.getOrDefault(
                        "address", ""));
        depot.setUpdatedAt(LocalDateTime.now().format(
                DateTimeFormatter.ofPattern(
                        "yyyy-MM-dd HH:mm:ss")));

        depotRepository.save(depot);
        return "Depot saved: "
                + depot.getDepotName()
                + " (" + depot.getLatitude()
                + ", " + depot.getLongitude() + ")";
    }

    // ── Delete depot settings ───────────────────────────────
    @DeleteMapping("/{managerId}")
    public String deleteDepot(
            @PathVariable String managerId) {
        depotRepository.deleteById(managerId);
        return "Depot settings removed for: " + managerId;
    }
}