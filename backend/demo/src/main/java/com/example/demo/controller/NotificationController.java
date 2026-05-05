package com.example.demo.controller;

import com.example.demo.model.Notification;
import com.example.demo.repository.NotificationRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/notifications")
public class NotificationController {

    @Autowired
    private NotificationRepository notificationRepository;

    // ── Get all notifications for driver ────────────────────
    @GetMapping("/{driverId}")
    public List<Notification> getAll(
            @PathVariable String driverId) {
        return notificationRepository
                .findByDriverIdOrderByCreatedAtDesc(
                        driverId);
    }

    // ── Get unread count (for badge) ────────────────────────
    @GetMapping("/{driverId}/unread-count")
    public Map<String, Long> getUnreadCount(
            @PathVariable String driverId) {
        long count = notificationRepository
                .countByDriverIdAndIsReadFalse(driverId);
        return Map.of("count", count);
    }

    // ── Mark single notification as read ────────────────────
    @PutMapping("/read/{id}")
    public String markRead(@PathVariable Long id) {
        return notificationRepository.findById(id)
                .map(n -> {
                    n.setRead(true);
                    notificationRepository.save(n);
                    return "Marked as read";
                })
                .orElse("Notification not found");
    }

    // ── Mark all as read for a driver ───────────────────────
    @PutMapping("/read-all/{driverId}")
    public String markAllRead(
            @PathVariable String driverId) {
        List<Notification> unread =
                notificationRepository
                        .findByDriverIdAndIsReadFalse(
                                driverId);
        unread.forEach(n -> n.setRead(true));
        notificationRepository.saveAll(unread);
        return "All marked as read: " + unread.size();
    }

    // ── Delete all notifications for driver ─────────────────
    @DeleteMapping("/{driverId}")
    public String clearAll(
            @PathVariable String driverId) {
        List<Notification> all = notificationRepository
                .findByDriverIdOrderByCreatedAtDesc(
                        driverId);
        notificationRepository.deleteAll(all);
        return "Cleared " + all.size()
                + " notifications";
    }
}