package com.example.demo.repository;

import com.example.demo.model.ManagerAccount;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.Optional;

@Repository
public interface ManagerAccountRepository
        extends JpaRepository<ManagerAccount, String> {
    Optional<ManagerAccount> findByEmail(String email);
    boolean existsByEmail(String email);
    boolean existsByManagerId(String managerId);
}
