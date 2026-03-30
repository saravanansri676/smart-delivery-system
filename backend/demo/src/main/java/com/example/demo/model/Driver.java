package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "drivers")
public class Driver {
    @Id
    private String driverId;
    private String vehicleNo;
    private String workStartTime;
    private String workEndTime;
    private double fuelLevel;
    private double vehicleCapacity;
    private String status;
    private double currentLatitude;
    private double currentLongitude;
}