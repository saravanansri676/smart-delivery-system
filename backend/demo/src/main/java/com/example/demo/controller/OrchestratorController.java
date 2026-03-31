package com.example.demo.controller;

import com.example.demo.service.DeliveryOrchestratorService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@RestController
@RequestMapping("/delivery")
public class OrchestratorController {

    @Autowired
    private DeliveryOrchestratorService orchestratorService;

    // MASTER API - Generate full delivery plan
    // Manager calls this once → system handles everything
    @PostMapping("/plan")
    public Map<String, Object> generateDeliveryPlan(
            @RequestParam double startLat,
            @RequestParam double startLon) {
        return orchestratorService
                .generateFullDeliveryPlan(startLat, startLon);
    }

    // Live status dashboard for manager
    @GetMapping("/status")
    public Map<String, Object> getLiveStatus() {
        return orchestratorService.getLiveStatus();
    }
}
