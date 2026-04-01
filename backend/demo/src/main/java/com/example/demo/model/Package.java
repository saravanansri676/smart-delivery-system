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
    private String deadlineDate;    // format: "yyyy-MM-dd HH:mm"
    private double weightKg;
    private String size;            // SMALL, MEDIUM, LARGE
    private String status;          // IN_STORE, ASSIGNED, MOVING, DELIVERED
    private int priority;
    private String assignedDriverId;
}