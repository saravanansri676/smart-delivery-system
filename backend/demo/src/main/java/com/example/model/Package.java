package com.example.model;

import lombok.Data;

@Data
public class Package {
    private String packageId;
    private String packageName;
    private String address;
    private double latitude;
    private double longitude;
    private String deadline;       // format: "HH:mm"
    private String size;           // SMALL, MEDIUM, LARGE
    private String status;         // IN_STORE, ASSIGNED, MOVING, DELIVERED
    private int priority;          // 1 = highest, assigned by system
    private String assignedDriverId;
}
