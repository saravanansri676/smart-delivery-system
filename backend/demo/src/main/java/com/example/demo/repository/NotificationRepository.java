package com.example.demo.repository;

import com.example.demo.model.Notification;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface NotificationRepository
        extends JpaRepository<Notification, Long> {

    // All notifications for a driver
    // newest first
    List<Notification> findByDriverIdOrderByCreatedAtDesc(
            String driverId);

    // Only unread notifications
    List<Notification> findByDriverIdAndIsReadFalse(
            String driverId);

    // Count of unread (for badge)
    long countByDriverIdAndIsReadFalse(String driverId);
}