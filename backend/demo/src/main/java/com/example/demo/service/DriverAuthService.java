package com.example.demo.service;

import com.example.demo.model.DriverAccount;
import com.example.demo.model.DriverRequest;
import com.example.demo.repository.DriverAccountRepository;
import com.example.demo.repository.DriverRequestRepository;
import com.example.demo.repository.ManagerAccountRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.security.MessageDigest;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.Optional;

@Service
public class DriverAuthService {

    @Autowired
    private DriverAccountRepository driverAccountRepository;

    @Autowired
    private DriverRequestRepository driverRequestRepository;

    @Autowired
    private ManagerAccountRepository managerAccountRepository;

    // ── Utilities ──────────────────────────────────────────

    public String hashPassword(String raw) {
        try {
            MessageDigest digest =
                    MessageDigest.getInstance("SHA-256");
            byte[] hash = digest.digest(
                    raw.getBytes("UTF-8"));
            StringBuilder hex = new StringBuilder();
            for (byte b : hash) {
                String h = Integer.toHexString(0xff & b);
                if (h.length() == 1) hex.append('0');
                hex.append(h);
            }
            return hex.toString();
        } catch (Exception e) {
            return raw;
        }
    }

    // Reuse same hash for security answers
    // Lowercase the answer before hashing
    // so "Chennai" and "chennai" both work
    public String hashAnswer(String answer) {
        return hashPassword(answer.trim().toLowerCase());
    }

    private String generateRequestId() {
        return "REQ" + System.currentTimeMillis();
    }

    // ── Login ───────────────────────────────────────────────

    public String login(String driverId, String password) {
        Optional<DriverAccount> account =
                driverAccountRepository.findById(driverId);
        if (account.isEmpty()) return "INVALID";

        DriverAccount driver = account.get();

        if (!driver.getPassword().equals(
                hashPassword(password))) return "INVALID";

        if ("PENDING".equals(driver.getAccountStatus()))
            return "PENDING";

        return "SUCCESS:" + driver.getName()
                + ":" + driver.getMobileNumber()
                + ":" + driver.getCompanyName()
                + ":" + driver.getManagerId();
    }

    // ── Registration — Submit request ───────────────────────
    // Now also accepts securityQuestion + securityAnswer

    public String initiateRegistration(
            String driverId, String name,
            String companyName, String managerId,
            String mobileNumber, String password,
            String securityQuestion, String securityAnswer) {

        // Driver ID already exists
        if (driverAccountRepository.existsById(driverId))
            return "ID_EXISTS";

        // Mobile already registered
        if (driverAccountRepository
                .existsByMobileNumber(mobileNumber))
            return "MOBILE_EXISTS";

        // Manager must exist
        if (!managerAccountRepository.existsById(managerId))
            return "MANAGER_NOT_FOUND";

        // Already has a pending request
        if (driverRequestRepository
                .existsByDriverIdAndStatus(driverId, "PENDING"))
            return "REQUEST_PENDING";

        // Validate security question and answer
        if (securityQuestion == null
                || securityQuestion.trim().isEmpty())
            return "SECURITY_QUESTION_REQUIRED";

        if (securityAnswer == null
                || securityAnswer.trim().isEmpty())
            return "SECURITY_ANSWER_REQUIRED";

        // Build request
        DriverRequest request = new DriverRequest();
        request.setRequestId(generateRequestId());
        request.setDriverId(driverId);
        request.setName(name);
        request.setCompanyName(companyName);
        request.setManagerId(managerId);
        request.setMobileNumber(mobileNumber);
        request.setHashedPassword(hashPassword(password));
        request.setSecurityQuestion(securityQuestion);
        request.setHashedSecurityAnswer(
                hashAnswer(securityAnswer));
        request.setStatus("PENDING");
        request.setRequestedAt(
                LocalDateTime.now().format(
                        DateTimeFormatter.ofPattern(
                                "yyyy-MM-dd HH:mm:ss")));

        driverRequestRepository.save(request);
        return "REQUEST_SENT";
    }

    // ── Manager accepts registration request ────────────────
    // Copies all data including security question to account

    public String acceptRequest(String requestId) {
        Optional<DriverRequest> opt =
                driverRequestRepository.findById(requestId);
        if (opt.isEmpty()) return "NOT_FOUND";

        DriverRequest request = opt.get();

        if (!"PENDING".equals(request.getStatus()))
            return "ALREADY_PROCESSED";

        // Create driver account with security question
        DriverAccount account = new DriverAccount();
        account.setDriverId(request.getDriverId());
        account.setName(request.getName());
        account.setCompanyName(request.getCompanyName());
        account.setManagerId(request.getManagerId());
        account.setMobileNumber(request.getMobileNumber());
        account.setPassword(request.getHashedPassword());
        account.setSecurityQuestion(
                request.getSecurityQuestion());
        account.setSecurityAnswer(
                request.getHashedSecurityAnswer());
        account.setAccountStatus("ACTIVE");
        account.setOtp(null);
        account.setOtpExpiry(0);

        driverAccountRepository.save(account);

        // Mark request accepted
        request.setStatus("ACCEPTED");
        driverRequestRepository.save(request);

        return "ACCEPTED:" + request.getDriverId()
                + ":" + request.getName();
    }

    // ── Manager rejects request ──────────────────────────────

    public String rejectRequest(String requestId) {
        Optional<DriverRequest> opt =
                driverRequestRepository.findById(requestId);
        if (opt.isEmpty()) return "NOT_FOUND";

        DriverRequest request = opt.get();

        if (!"PENDING".equals(request.getStatus()))
            return "ALREADY_PROCESSED";

        request.setStatus("REJECTED");
        driverRequestRepository.save(request);

        return "REJECTED:" + request.getDriverId();
    }

    // ── Forgot Password — Option 4 ──────────────────────────
    // Step 1: Driver enters driverId
    //         → return the security question for that driver
    //         so they know what to answer

    public String getSecurityQuestion(String driverId) {
        Optional<DriverAccount> account =
                driverAccountRepository.findById(driverId);
        if (account.isEmpty()) return "NOT_FOUND";

        String question =
                account.get().getSecurityQuestion();
        if (question == null || question.isEmpty())
            return "NO_SECURITY_QUESTION";

        // Return question so frontend can display it
        return "QUESTION:" + question;
    }

    // ── Forgot Password — Step 2: Verify & Reset ────────────
    // Driver provides:
    //   - driverId
    //   - registered mobile number  ← must match DB
    //   - security answer            ← must match DB (hashed)
    //   - new password

    public String resetPasswordWithVerification(
            String driverId,
            String mobileNumber,
            String securityAnswer,
            String newPassword) {

        Optional<DriverAccount> opt =
                driverAccountRepository.findById(driverId);
        if (opt.isEmpty()) return "NOT_FOUND";

        DriverAccount driver = opt.get();

        // Check 1: Mobile must match
        if (!driver.getMobileNumber()
                .equals(mobileNumber.trim())) {
            return "MOBILE_MISMATCH";
        }

        // Check 2: Security answer must match (case-insensitive)
        String hashedInput = hashAnswer(securityAnswer);
        if (!driver.getSecurityAnswer()
                .equals(hashedInput)) {
            return "WRONG_ANSWER";
        }

        // Both checks passed — reset password
        driver.setPassword(hashPassword(newPassword));
        driverAccountRepository.save(driver);

        return "SUCCESS";
    }
}