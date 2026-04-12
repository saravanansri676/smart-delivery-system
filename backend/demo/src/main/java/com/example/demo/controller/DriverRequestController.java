package com.example.demo.controller;

import com.example.demo.model.DriverRequest;
import com.example.demo.repository.DriverRequestRepository;
import com.example.demo.service.DriverAuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/driver-requests")
public class DriverRequestController {

    @Autowired
    private DriverAuthService driverAuthService;

    @Autowired
    private DriverRequestRepository driverRequestRepository;

    // ── Driver submits registration form ────────────────────
    // Now includes securityQuestion + securityAnswer
    @PostMapping("/register")
    public String submitRequest(
            @RequestBody Map<String, String> body) {
        return driverAuthService.initiateRegistration(
                body.get("driverId"),
                body.get("name"),
                body.get("companyName"),
                body.get("managerId"),
                body.get("mobileNumber"),
                body.get("password"),
                body.get("securityQuestion"),
                body.get("securityAnswer")
        );
    }

    // ── Manager polls for pending requests ──────────────────
    @GetMapping("/pending/{managerId}")
    public List<DriverRequest> getPendingRequests(
            @PathVariable String managerId) {
        return driverRequestRepository
                .findByManagerIdAndStatus(
                        managerId, "PENDING");
    }

    // ── Manager accepts ─────────────────────────────────────
    @PutMapping("/accept/{requestId}")
    public String acceptRequest(
            @PathVariable String requestId) {
        return driverAuthService.acceptRequest(requestId);
    }

    // ── Manager rejects ─────────────────────────────────────
    @PutMapping("/reject/{requestId}")
    public String rejectRequest(
            @PathVariable String requestId) {
        return driverAuthService.rejectRequest(requestId);
    }

    // ── Manager views all requests (any status) ─────────────
    @GetMapping("/all/{managerId}")
    public List<DriverRequest> getAllRequests(
            @PathVariable String managerId) {
        return driverRequestRepository
                .findByManagerId(managerId);
    }
}