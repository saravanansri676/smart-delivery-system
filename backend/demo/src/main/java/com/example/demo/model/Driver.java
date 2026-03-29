package com.example.demo.model;

import lombok.Data;

@Data
public class Driver {
    private String driverId;
    private String vehicleNo;
    private String workStartTime;   // format: "HH:mm"
    private String workEndTime;
    private double fuelLevel;       // in litres
    private double vehicleCapacity; // max packages
    private String status;          // AVAILABLE, ON_DELIVERY
    private double currentLatitude;
    private double currentLongitude;
}
