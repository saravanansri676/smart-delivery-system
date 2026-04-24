package com.example.demo.controller;

import com.example.demo.model.DepotSettings;
import com.example.demo.model.Manager;
import com.example.demo.model.ManagerAccount;
import com.example.demo.repository.DepotSettingsRepository;
import com.example.demo.repository.ManagerAccountRepository;
import com.example.demo.repository.ManagerRepository;
import com.example.demo.service.GeocodingService;
import com.example.demo.service.ManagerAuthService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/auth/manager")
public class ManagerAuthController {

    @Autowired
    private ManagerAuthService authService;

    @Autowired
    private ManagerAccountRepository accountRepository;

    @Autowired
    private ManagerRepository managerRepository;

    @Autowired
    private DepotSettingsRepository depotRepository;

    @Autowired
    private GeocodingService geocodingService;

    // ── Login ───────────────────────────────────────────────
    @PostMapping("/login")
    public String login(
            @RequestBody Map<String, String> body) {
        return authService.login(
                body.get("managerId"),
                body.get("password"));
    }

    // ── Register Step 1 ─────────────────────────────────────
    @PostMapping("/register")
    public String register(
            @RequestBody Map<String, String> body) {
        return authService.initiateRegistration(
                body.get("managerId"),
                body.get("name"),
                body.get("companyName"),
                body.get("email"),
                body.get("password"));
    }

    // ── Register Step 2 ─────────────────────────────────────
    @PostMapping("/verify-registration")
    public String verifyRegistration(
            @RequestBody Map<String, String> body) {
        return authService.verifyRegistrationOTP(
                body.get("managerId"),
                body.get("otp"));
    }

    // ── Forgot password Step 1 ──────────────────────────────
    @PostMapping("/forgot-password")
    public String forgotPassword(
            @RequestBody Map<String, String> body) {
        return authService.initiateForgotPassword(
                body.get("managerId"));
    }

    // ── Forgot password Step 2 ──────────────────────────────
    @PostMapping("/reset-password")
    public String resetPassword(
            @RequestBody Map<String, String> body) {
        return authService.resetPassword(
                body.get("managerId"),
                body.get("otp"),
                body.get("newPassword"));
    }

    // ── Get manager profile ─────────────────────────────────
    @GetMapping("/profile/{managerId}")
    public Map<String, Object> getProfile(
            @PathVariable String managerId) {

        Map<String, Object> result = new HashMap<>();

        Optional<ManagerAccount> account =
                accountRepository.findById(managerId);
        if (account.isPresent()) {
            ManagerAccount mgr = account.get();
            result.put("managerId", mgr.getManagerId());
            result.put("name", mgr.getName());
            result.put("email", mgr.getEmail());
            result.put("companyName",
                    mgr.getCompanyName());
            result.put("accountStatus",
                    mgr.getAccountStatus());
        }

        Optional<Manager> manager =
                managerRepository.findById(managerId);
        if (manager.isPresent()) {
            Manager mgr = manager.get();
            result.put("age", mgr.getAge());
            result.put("sex", mgr.getSex());
            result.put("mobileNumber",
                    mgr.getMobileNumber());
            result.put("officeLocation",
                    mgr.getOfficeLocation());
            result.put("joinedDate",
                    mgr.getJoinedDate());
        }

        return result;
    }

    // ── Update manager profile ──────────────────────────────
    // When officeLocation + coordinates are provided,
    // automatically saves them as depot settings too.
    // This removes the need for a separate Depot Settings screen.
    @PutMapping("/profile/{managerId}")
    public String updateProfile(
            @PathVariable String managerId,
            @RequestBody Map<String, Object> body) {

        // Update ManagerAccount
        Optional<ManagerAccount> accountOpt =
                accountRepository.findById(managerId);
        if (accountOpt.isEmpty())
            return "Manager account not found";

        ManagerAccount account = accountOpt.get();
        if (body.containsKey("name"))
            account.setName(
                    (String) body.get("name"));
        if (body.containsKey("email"))
            account.setEmail(
                    (String) body.get("email"));
        if (body.containsKey("companyName"))
            account.setCompanyName(
                    (String) body.get("companyName"));
        accountRepository.save(account);

        // Update or create Manager record
        Manager manager = managerRepository
                .findById(managerId)
                .orElse(new Manager());

        manager.setManagerId(managerId);
        manager.setName(account.getName());
        manager.setEmail(account.getEmail());
        manager.setCompanyName(account.getCompanyName());

        if (body.containsKey("age")) {
            Object ageVal = body.get("age");
            if (ageVal instanceof Integer)
                manager.setAge((Integer) ageVal);
            else if (ageVal instanceof String) {
                try {
                    manager.setAge(Integer.parseInt(
                            (String) ageVal));
                } catch (NumberFormatException ignored) {}
            }
        }
        if (body.containsKey("sex"))
            manager.setSex((String) body.get("sex"));
        if (body.containsKey("mobileNumber"))
            manager.setMobileNumber(
                    (String) body.get("mobileNumber"));
        if (body.containsKey("officeLocation"))
            manager.setOfficeLocation(
                    (String) body.get("officeLocation"));
        if (body.containsKey("joinedDate"))
            manager.setJoinedDate(
                    (String) body.get("joinedDate"));

        managerRepository.save(manager);

        // ── Auto-save depot from office location ────────────
        // If the request includes lat/lon (from address
        // autocomplete in the profile edit screen),
        // save them as the depot for this manager.
        // No separate depot screen needed.
        if (body.containsKey("officeLatitude")
                && body.containsKey("officeLongitude")) {

            double lat = ((Number) body.get(
                    "officeLatitude")).doubleValue();
            double lon = ((Number) body.get(
                    "officeLongitude")).doubleValue();
            String address = (String) body.getOrDefault(
                    "officeLocation", "");
            String depotName = account.getCompanyName()
                    + " Office";

            DepotSettings depot = depotRepository
                    .findById(managerId)
                    .orElse(new DepotSettings());

            depot.setManagerId(managerId);
            depot.setDepotName(depotName);
            depot.setLatitude(lat);
            depot.setLongitude(lon);
            depot.setAddress(address);
            depot.setUpdatedAt(LocalDateTime.now()
                    .format(DateTimeFormatter.ofPattern(
                            "yyyy-MM-dd HH:mm:ss")));

            depotRepository.save(depot);
        }

        return "Profile updated successfully";
    }
}