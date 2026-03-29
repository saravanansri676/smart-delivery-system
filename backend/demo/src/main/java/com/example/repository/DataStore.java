package com.example.repository;

import com.example.demo.model.Driver;
import com.example.demo.model.Package;
import org.springframework.stereotype.Component;

import java.util.ArrayList;
import java.util.List;

@Component
public class DataStore {
    public List<Package> packages = new ArrayList<>();
    public List<Driver> drivers = new ArrayList<>();
}