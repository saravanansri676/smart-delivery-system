package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "managers")
public class Manager {
    @Id
    private String managerId;
    private String name;
    private int age;
    private String sex;
    private String email;
    private String mobileNumber;
    private String companyName;
    private String officeLocation;
    private String joinedDate;
    private String accountStatus;   // ACTIVE, SUSPENDED
    private int totalPackagesManaged;
    private int totalDriversAssigned;
}