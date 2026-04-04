package com.example.demo.controller;

import com.example.demo.service.ManagerAuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;
import java.util.Map;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;
import com.example.demo.repository.ManagerAccountRepository;

@RestController
@RequestMapping("/auth/manager")
public class ManagerAuthController {

    @Autowired
    private ManagerAuthService authService;

    @Autowired
    private ManagerAccountRepository accountRepository;

    // Login
    @PostMapping("/login")
    public String login(@RequestBody Map<String, String> body) {
        return authService.login(
                body.get("managerId"),
                body.get("password")
        );
    }

    // Register - Step 1: send OTP
    @PostMapping("/register")
    public String register(@RequestBody Map<String, String> body) {
        return authService.initiateRegistration(
                body.get("managerId"),
                body.get("name"),
                body.get("companyName"),
                body.get("email"),
                body.get("password")
        );
    }

    // Register - Step 2: verify OTP
    @PostMapping("/verify-registration")
    public String verifyRegistration(
            @RequestBody Map<String, String> body) {
        return authService.verifyRegistrationOTP(
                body.get("managerId"),
                body.get("otp")
        );
    }

    // Forgot password - Step 1: send OTP
    @PostMapping("/forgot-password")
    public String forgotPassword(
            @RequestBody Map<String, String> body) {
        return authService.initiateForgotPassword(
                body.get("managerId")
        );
    }

    // Forgot password - Step 2: verify OTP + reset
    @PostMapping("/reset-password")
    public String resetPassword(
            @RequestBody Map<String, String> body) {
        return authService.resetPassword(
                body.get("managerId"),
                body.get("otp"),
                body.get("newPassword")
        );
    }

    // Get manager profile by ID
    @GetMapping("/profile/{managerId}")
    public Map<String, Object> getProfile(
            @PathVariable String managerId) {
        Optional<com.example.demo.model.ManagerAccount> account =
                accountRepository.findById(managerId);

        Map<String, Object> result = new HashMap<>();
        if (account.isPresent()) {
            com.example.demo.model.ManagerAccount mgr =
                    account.get();
            result.put("managerId", mgr.getManagerId());
            result.put("name", mgr.getName());
            result.put("email", mgr.getEmail());
            result.put("companyName", mgr.getCompanyName());
            result.put("accountStatus", mgr.getAccountStatus());
        }
        return result;
    }
}