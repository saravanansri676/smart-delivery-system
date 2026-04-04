package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "manager_accounts")
public class ManagerAccount {
    @Id
    private String managerId;
    private String name;
    private String companyName;
    private String email;
    private String password;        // hashed
    private String accountStatus;   // ACTIVE, SUSPENDED, PENDING
    private String otp;             // temporary OTP
    private long otpExpiry;         // timestamp
}