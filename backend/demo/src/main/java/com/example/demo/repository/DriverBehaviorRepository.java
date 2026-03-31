package com.example.demo.repository;

import com.example.demo.model.DriverBehavior;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface DriverBehaviorRepository
        extends JpaRepository<DriverBehavior, Long> {
    List<DriverBehavior> findByDriverId(String driverId);
}
