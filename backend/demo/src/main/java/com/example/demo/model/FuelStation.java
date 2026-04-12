package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "fuel_stations")
public class FuelStation {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name;        // e.g. "IOC Adyar"
    private String provider;    // e.g. "Indian Oil"
    private double latitude;
    private double longitude;
    private String city;        // e.g. "Chennai"
    private boolean active;     // soft delete support
}
