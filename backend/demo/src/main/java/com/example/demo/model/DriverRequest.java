package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "driver_requests")
public class DriverRequest {

    @Id
    private String requestId;          // REQ + timestamp

    private String driverId;
    private String name;
    private String companyName;
    private String managerId;
    private String mobileNumber;
    private String hashedPassword;

    // Security question stored here during pending phase
    // Moved to DriverAccount when accepted
    private String securityQuestion;
    private String hashedSecurityAnswer;

    // PENDING, ACCEPTED, REJECTED
    private String status;

    private String requestedAt;        // yyyy-MM-dd HH:mm:ss
}