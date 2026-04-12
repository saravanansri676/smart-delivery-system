package com.example.demo.controller;

import com.example.demo.model.DriverAccount;
import com.example.demo.repository.DriverAccountRepository;
import com.example.demo.service.DriverAuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/auth/driver")
public class DriverAuthController {

    @Autowired
    private DriverAuthService driverAuthService;

    @Autowired
    private DriverAccountRepository driverAccountRepository;

    // ── Login ───────────────────────────────────────────────
    @PostMapping("/login")
    public String login(
            @RequestBody Map<String, String> body) {
        return driverAuthService.login(
                body.get("driverId"),
                body.get("password")
        );
    }

    // ── Get Driver Profile ──────────────────────────────────
    @GetMapping("/profile/{driverId}")
    public Map<String, Object> getProfile(
            @PathVariable String driverId) {
        Optional<DriverAccount> account =
                driverAccountRepository.findById(driverId);
        Map<String, Object> result = new HashMap<>();
        if (account.isPresent()) {
            DriverAccount driver = account.get();
            result.put("driverId", driver.getDriverId());
            result.put("name", driver.getName());
            result.put("mobileNumber",
                    driver.getMobileNumber());
            result.put("companyName",
                    driver.getCompanyName());
            result.put("managerId", driver.getManagerId());
            result.put("accountStatus",
                    driver.getAccountStatus());
            // Note: securityQuestion and securityAnswer
            // are intentionally NOT exposed here
        }
        return result;
    }

    // ── Forgot Password Step 1 ──────────────────────────────
    // Driver enters their ID → get their security question
    // Frontend displays the question to the driver
    @PostMapping("/forgot-password/question")
    public String getSecurityQuestion(
            @RequestBody Map<String, String> body) {
        return driverAuthService.getSecurityQuestion(
                body.get("driverId")
        );
    }

    // ── Forgot Password Step 2 ──────────────────────────────
    // Driver provides mobile + answer + new password
    // Both mobile and answer must match DB records
    @PostMapping("/forgot-password/reset")
    public String resetPassword(
            @RequestBody Map<String, String> body) {
        return driverAuthService
                .resetPasswordWithVerification(
                        body.get("driverId"),
                        body.get("mobileNumber"),
                        body.get("securityAnswer"),
                        body.get("newPassword")
                );
    }
}