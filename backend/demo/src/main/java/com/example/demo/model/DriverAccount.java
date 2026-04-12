package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "driver_accounts")
public class DriverAccount {

    @Id
    private String driverId;
    private String name;
    private String companyName;
    private String managerId;
    private String mobileNumber;
    private String password;           // SHA-256 hashed
    private String accountStatus;      // ACTIVE, PENDING

    // Security Question for password reset
    private String securityQuestion;   // The question text
    private String securityAnswer;     // SHA-256 hashed answer

    // OTP fields kept for future use but not used now
    private String otp;
    private long otpExpiry;
}
