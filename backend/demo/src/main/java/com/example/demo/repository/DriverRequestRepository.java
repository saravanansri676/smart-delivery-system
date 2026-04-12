package com.example.demo.repository;

import com.example.demo.model.DriverRequest;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DriverRequestRepository
        extends JpaRepository<DriverRequest, String> {

    // Get all pending requests for a manager
    List<DriverRequest> findByManagerIdAndStatus(
            String managerId, String status);

    // Get all requests for a manager (any status)
    List<DriverRequest> findByManagerId(String managerId);

    // Check if driverId already has a pending request
    boolean existsByDriverIdAndStatus(
            String driverId, String status);
}