package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "packages")
public class Package {
    @Id
    private String packageId;
    private String packageName;
    private String receiverName;
    private String receiverPhone;
    private String address;
    private double latitude;
    private double longitude;
    private String deadline;        // HH:mm - kept for TSP calculations
    private String deadlineDate;    // yyyy-MM-dd HH:mm - for display
    private double weightKg;
    private String size;
    private String status;
    private int priority;
    private String assignedDriverId;
}