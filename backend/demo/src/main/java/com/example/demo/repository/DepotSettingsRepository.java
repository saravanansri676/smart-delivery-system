package com.example.demo.repository;

import com.example.demo.model.DepotSettings;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface DepotSettingsRepository
        extends JpaRepository<DepotSettings, String> {
}