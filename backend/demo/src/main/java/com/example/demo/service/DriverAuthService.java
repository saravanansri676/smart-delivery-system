package com.example.demo.service;

import com.example.demo.model.Driver;
import com.example.demo.model.DriverAccount;
import com.example.demo.model.DriverRequest;
import com.example.demo.repository.DriverAccountRepository;
import com.example.demo.repository.DriverRepository;
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

    // ✅ Needed to create Driver record on acceptance
    @Autowired
    private DriverRepository driverRepository;

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

    public String initiateRegistration(
            String driverId, String name,
            String companyName, String managerId,
            String mobileNumber, String password,
            String securityQuestion,
            String securityAnswer) {

        if (driverAccountRepository.existsById(driverId))
            return "ID_EXISTS";

        if (driverAccountRepository
                .existsByMobileNumber(mobileNumber))
            return "MOBILE_EXISTS";

        if (!managerAccountRepository.existsById(managerId))
            return "MANAGER_NOT_FOUND";

        if (driverRequestRepository
                .existsByDriverIdAndStatus(
                        driverId, "PENDING"))
            return "REQUEST_PENDING";

        if (securityQuestion == null
                || securityQuestion.trim().isEmpty())
            return "SECURITY_QUESTION_REQUIRED";

        if (securityAnswer == null
                || securityAnswer.trim().isEmpty())
            return "SECURITY_ANSWER_REQUIRED";

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
    // Creates BOTH DriverAccount AND Driver records.
    //
    // DriverAccount → handles login/auth
    // Driver        → handles routes, assignments,
    //                 vehicle info, status, location
    //
    // Driver is created with basic info from the request.
    // Remaining fields (vehicleNo, vehicleType, capacity,
    // fuelLevel, location) are set to safe defaults and
    // updated later by the driver via their profile screen.

    public String acceptRequest(String requestId) {
        Optional<DriverRequest> opt =
                driverRequestRepository.findById(requestId);
        if (opt.isEmpty()) return "NOT_FOUND";

        DriverRequest request = opt.get();

        if (!"PENDING".equals(request.getStatus()))
            return "ALREADY_PROCESSED";

        // ── 1. Create DriverAccount (auth) ─────────────────
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

        // ── 2. Create Driver (operations) ──────────────────
        // Only create if not already in drivers table
        if (!driverRepository.existsById(
                request.getDriverId())) {

            Driver driver = new Driver();
            driver.setDriverId(request.getDriverId());
            driver.setName(request.getName());
            driver.setMobileNumber(
                    request.getMobileNumber());
            driver.setCompanyName(
                    request.getCompanyName());

            // Safe defaults — driver updates via profile
            driver.setStatus("AVAILABLE");
            driver.setFuelLevel("FULL");
            driver.setVehicleNo("");
            driver.setVehicleType("BIKE");
            driver.setVehicleCapacity(0);
            driver.setWorkStartTime("09:00");
            driver.setWorkEndTime("16:00");
            driver.setCurrentLatitude(0);
            driver.setCurrentLongitude(0);
            driver.setAge(0);
            driver.setSex("");
            driver.setPackagesAssigned(0);
            driver.setPackagesDelivered(0);
            driver.setAverageRating(0.0);
            driver.setPenaltyCount(0);
            driver.setPenaltyReasons("");
            driver.setDrivingScore(100.0);

            driverRepository.save(driver);
        }

        // ── 3. Mark request as accepted ────────────────────
        request.setStatus("ACCEPTED");
        driverRequestRepository.save(request);

        return "ACCEPTED:" + request.getDriverId()
                + ":" + request.getName();
    }

    // ── Manager rejects request ─────────────────────────────

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

    // ── Forgot Password Step 1 ──────────────────────────────
    // Return security question for given driverId

    public String getSecurityQuestion(String driverId) {
        Optional<DriverAccount> account =
                driverAccountRepository.findById(driverId);
        if (account.isEmpty()) return "NOT_FOUND";

        String question =
                account.get().getSecurityQuestion();
        if (question == null || question.isEmpty())
            return "NO_SECURITY_QUESTION";

        return "QUESTION:" + question;
    }

    // ── Forgot Password Step 2 ──────────────────────────────
    // Verify mobile + security answer → reset password

    public String resetPasswordWithVerification(
            String driverId,
            String mobileNumber,
            String securityAnswer,
            String newPassword) {

        Optional<DriverAccount> opt =
                driverAccountRepository.findById(driverId);
        if (opt.isEmpty()) return "NOT_FOUND";

        DriverAccount driver = opt.get();

        if (!driver.getMobileNumber()
                .equals(mobileNumber.trim()))
            return "MOBILE_MISMATCH";

        String hashedInput = hashAnswer(securityAnswer);
        if (!driver.getSecurityAnswer().equals(hashedInput))
            return "WRONG_ANSWER";

        driver.setPassword(hashPassword(newPassword));
        driverAccountRepository.save(driver);
        return "SUCCESS";
    }
}