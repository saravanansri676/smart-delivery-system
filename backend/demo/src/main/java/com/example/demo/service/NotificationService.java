package com.example.demo.service;

import com.example.demo.model.Notification;
import com.example.demo.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Service
public class NotificationService {

    @Autowired
    private NotificationRepository notificationRepository;

    private static final DateTimeFormatter FMT =
            DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    // ── Generic create ───────────────────────────────────────
    public Notification create(String driverId,
                               String type, String message) {
        Notification n = new Notification();
        n.setDriverId(driverId);
        n.setType(type);
        n.setMessage(message);
        n.setRead(false);
        n.setCreatedAt(LocalDateTime.now().format(FMT));
        return notificationRepository.save(n);
    }

    // ── Convenience methods ──────────────────────────────────

    public void notifyPackageAssigned(String driverId,
                                      int packageCount) {
        create(driverId, "PACKAGE_ASSIGNED",
                packageCount + " new package"
                        + (packageCount == 1 ? "" : "s")
                        + " assigned to you. "
                        + "Check the Packages section!");
    }

    public void notifyIncident(String driverId,
                               String reportingDriverName,
                               String reportingDriverId,
                               String issue) {
        create(driverId, "INCIDENT",
                "Driver " + reportingDriverName
                        + " (" + reportingDriverId + ")"
                        + " reported: " + issue
                        + ". Stay alert on the road.");
    }

    public void notifyDeadlineWarning(String driverId,
                                      String packageName, String deadline) {
        create(driverId, "DEADLINE_WARNING",
                "Less time to deliver \""
                        + packageName + "\"! "
                        + "Deadline: " + deadline
                        + ". Hurry up!");
    }

    public void notifyAllDelivered(String driverId) {
        create(driverId, "GENERAL",
                "Great job! All packages delivered "
                        + "successfully. You are now Available.");
    }
}