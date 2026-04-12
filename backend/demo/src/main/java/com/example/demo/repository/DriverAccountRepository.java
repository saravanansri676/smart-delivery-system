package com.example.demo.repository;

import com.example.demo.model.DriverAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface DriverAccountRepository
        extends JpaRepository<DriverAccount, String> {
    Optional<DriverAccount> findByMobileNumber(
            String mobileNumber);
    boolean existsByMobileNumber(String mobileNumber);
}
