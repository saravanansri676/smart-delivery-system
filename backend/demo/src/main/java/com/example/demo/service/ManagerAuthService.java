package com.example.demo.service;

import com.example.demo.model.ManagerAccount;
import com.example.demo.repository.ManagerAccountRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import java.security.MessageDigest;
import java.util.Optional;
import java.util.Random;

@Service
public class ManagerAuthService {

    @Autowired
    private ManagerAccountRepository accountRepository;

    @Autowired
    private EmailService emailService;

    // Hash password using SHA-256
    public String hashPassword(String password) {
        try {
            MessageDigest digest =
                    MessageDigest.getInstance("SHA-256");
            byte[] hash =
                    digest.digest(password.getBytes("UTF-8"));
            StringBuilder hexString = new StringBuilder();
            for (byte b : hash) {
                String hex = Integer.toHexString(0xff & b);
                if (hex.length() == 1) hexString.append('0');
                hexString.append(hex);
            }
            return hexString.toString();
        } catch (Exception e) {
            return password;
        }
    }

    // Generate 6-digit OTP
    public String generateOTP() {
        return String.valueOf(100000 +
                new Random().nextInt(900000));
    }

    // Login
    public String login(String managerId, String password) {
        Optional<ManagerAccount> account =
                accountRepository.findById(managerId);

        if (account.isEmpty()) {
            return "INVALID";
        }

        ManagerAccount mgr = account.get();

        if (!mgr.getPassword().equals(hashPassword(password))) {
            return "INVALID";
        }

        if ("PENDING".equals(mgr.getAccountStatus())) {
            return "PENDING";
        }

        return "SUCCESS:" + mgr.getName() +
                ":" + mgr.getEmail() +
                ":" + mgr.getCompanyName();
    }

    // Check if ID exists and send OTP for registration
    public String initiateRegistration(String managerId,
                                       String name, String company, String email,
                                       String password) {

        if (accountRepository.existsByManagerId(managerId)) {
            return "ID_EXISTS";
        }

        if (accountRepository.existsByEmail(email)) {
            return "EMAIL_EXISTS";
        }

        String otp = generateOTP();
        long expiry = System.currentTimeMillis() + 300000; // 5 mins

        ManagerAccount account = new ManagerAccount();
        account.setManagerId(managerId);
        account.setName(name);
        account.setCompanyName(company);
        account.setEmail(email);
        account.setPassword(hashPassword(password));
        account.setAccountStatus("PENDING");
        account.setOtp(otp);
        account.setOtpExpiry(expiry);
        accountRepository.save(account);

        emailService.sendOTP(email, otp, "Account Registration");
        return "OTP_SENT";
    }

    // Verify OTP for registration
    public String verifyRegistrationOTP(String managerId,
                                        String otp) {

        Optional<ManagerAccount> account =
                accountRepository.findById(managerId);

        if (account.isEmpty()) return "NOT_FOUND";

        ManagerAccount mgr = account.get();

        if (System.currentTimeMillis() > mgr.getOtpExpiry()) {
            return "EXPIRED";
        }

        if (!mgr.getOtp().equals(otp)) {
            return "INVALID_OTP";
        }

        mgr.setAccountStatus("ACTIVE");
        mgr.setOtp(null);
        accountRepository.save(mgr);
        return "SUCCESS:" + mgr.getName() +
                ":" + mgr.getEmail() +
                ":" + mgr.getCompanyName();
    }

    // Initiate forgot password
    public String initiateForgotPassword(String managerId) {
        Optional<ManagerAccount> account =
                accountRepository.findById(managerId);

        if (account.isEmpty()) return "NOT_FOUND";

        ManagerAccount mgr = account.get();
        String otp = generateOTP();
        long expiry = System.currentTimeMillis() + 300000;

        mgr.setOtp(otp);
        mgr.setOtpExpiry(expiry);
        accountRepository.save(mgr);

        emailService.sendOTP(mgr.getEmail(), otp,
                "Password Reset");
        return "OTP_SENT:" + mgr.getEmail();
    }

    // Verify OTP and reset password
    public String resetPassword(String managerId,
                                String otp, String newPassword) {

        Optional<ManagerAccount> account =
                accountRepository.findById(managerId);

        if (account.isEmpty()) return "NOT_FOUND";

        ManagerAccount mgr = account.get();

        if (System.currentTimeMillis() > mgr.getOtpExpiry()) {
            return "EXPIRED";
        }

        if (!mgr.getOtp().equals(otp)) {
            return "INVALID_OTP";
        }

        mgr.setPassword(hashPassword(newPassword));
        mgr.setOtp(null);
        accountRepository.save(mgr);
        return "SUCCESS";
    }
}
