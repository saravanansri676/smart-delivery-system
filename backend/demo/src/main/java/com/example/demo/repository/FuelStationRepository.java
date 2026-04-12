package com.example.demo.repository;

import com.example.demo.model.FuelStation;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface FuelStationRepository
        extends JpaRepository<FuelStation, Long> {

    // Get all active stations
    List<FuelStation> findByActiveTrue();

    // Get active stations by city
    List<FuelStation> findByCityAndActiveTrue(String city);
}