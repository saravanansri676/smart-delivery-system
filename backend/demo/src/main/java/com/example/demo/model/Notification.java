package com.example.demo.model;

import jakarta.persistence.*;
import lombok.Data;

@Data
@Entity
@Table(name = "notifications")
public class Notification {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String driverId;

    // PACKAGE_ASSIGNED, INCIDENT,
    // DEADLINE_WARNING, GENERAL
    private String type;

    private String message;

    // false = unread, true = read
    private boolean isRead;

    private String createdAt; // yyyy-MM-dd HH:mm:ss
}