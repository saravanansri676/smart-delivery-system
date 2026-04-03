package com.example.demo.model;

import jakarta.persistence.*;
        import lombok.Data;

@Data
@Entity
@Table(name = "drivers")
public class Driver {
    @Id
    private String driverId;
    private String name;
    private int age;
    private String sex;
    private String mobileNumber;
    private String vehicleNo;
    private String vehicleType;     // BIKE, VAN, TRUCK
    private String workStartTime;
    private String workEndTime;
    private String fuelLevel;       // FULL, MID, LOW
    private double vehicleCapacity;
    private String status;          // AVAILABLE, ON_DELIVERY, OFFLINE
    private double currentLatitude;
    private double currentLongitude;
    private String companyName;

    // Performance
    private int packagesAssigned;
    private int packagesDelivered;
    private double averageRating;

    // Behavior
    private int penaltyCount;
    private String penaltyReasons;  // comma separated
    private double drivingScore;
}