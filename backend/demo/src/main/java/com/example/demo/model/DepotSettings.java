package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "depot_settings")
public class DepotSettings {

    @Id
    private String managerId;       // one depot per manager

    private String depotName;       // e.g. "Main Warehouse"
    private double latitude;
    private double longitude;
    private String address;         // human-readable address
    private String updatedAt;       // last updated timestamp
}
