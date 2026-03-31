package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "driver_behavior")
public class DriverBehavior {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String driverId;
    private double avoidedFromLat;
    private double avoidedFromLon;
    private double avoidedToLat;
    private double avoidedToLon;
    private int avoidCount;        // how many times avoided
    private String reason;         // TRAFFIC, ROAD_CONDITION, PERSONAL
}
