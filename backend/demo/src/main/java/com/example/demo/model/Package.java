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
    private String address;
    private double latitude;
    private double longitude;
    private String deadline;
    private String size;
    private String status;
    private int priority;
    private String assignedDriverId;
}