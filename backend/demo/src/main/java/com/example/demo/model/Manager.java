package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "managers")
public class Manager {
    @Id
    private String managerId;
    private String companyName;
    private String name;
}
