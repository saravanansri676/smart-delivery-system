package com.example.demo.service;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import org.springframework.http.*;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.util.HashMap;
import java.util.Map;

@Service
public class GeocodingService {

    // Cache to avoid repeated API calls
    private final Map<String, double[]> cache = new HashMap<>();

    public double[] getCoordinates(String address) {
        // Check cache first
        if (cache.containsKey(address)) {
            System.out.println("Cache hit for: " + address);
            return cache.get(address);
        }

        // Try 3 levels of fallback
        double[] result = tryFullAddress(address);
        if (result != null) {
            cache.put(address, result);
            return result;
        }

        result = tryWithoutStreet(address);
        if (result != null) {
            cache.put(address, result);
            return result;
        }

        result = tryCityOnly(address);
        if (result != null) {
            cache.put(address, result);
            return result;
        }

        System.out.println(
                "All geocoding attempts failed for: " + address);
        return null; // Return null so controller can handle
    }

    // Level 1: Full structured search
    private double[] tryFullAddress(String address) {
        try {
            Thread.sleep(1000); // Respect Nominatim rate limit
            String encoded = URLEncoder.encode(
                    address, StandardCharsets.UTF_8);
            String url = "https://nominatim.openstreetmap.org"
                    + "/search?q=" + encoded
                    + "&format=json&limit=1"
                    + "&addressdetails=1&countrycodes=in";
            return callNominatim(url, "Full address");
        } catch (Exception e) {
            System.out.println("Level 1 failed: " + e.getMessage());
            return null;
        }
    }

    // Level 2: Without street, just area + city
    private double[] tryWithoutStreet(String address) {
        try {
            Thread.sleep(1000);
            // Extract city from address (last meaningful part)
            String[] parts = address.split(",");
            String simplified = parts.length > 1
                    ? parts[parts.length - 2].trim()
                      + "," + parts[parts.length - 1].trim()
                    : address;
            String encoded = URLEncoder.encode(
                    simplified, StandardCharsets.UTF_8);
            String url = "https://nominatim.openstreetmap.org"
                    + "/search?q=" + encoded
                    + "&format=json&limit=1&countrycodes=in";
            return callNominatim(url, "Simplified address");
        } catch (Exception e) {
            System.out.println("Level 2 failed: " + e.getMessage());
            return null;
        }
    }

    // Level 3: City + India only
    private double[] tryCityOnly(String address) {
        try {
            Thread.sleep(1000);
            String[] parts = address.split(",");
            String city = parts[parts.length - 1].trim()
                    + ", India";
            String encoded = URLEncoder.encode(
                    city, StandardCharsets.UTF_8);
            String url = "https://nominatim.openstreetmap.org"
                    + "/search?q=" + encoded
                    + "&format=json&limit=1&countrycodes=in";
            return callNominatim(url, "City only");
        } catch (Exception e) {
            System.out.println("Level 3 failed: " + e.getMessage());
            return null;
        }
    }

    // Common API caller
    private double[] callNominatim(String url, String level) {
        try {
            RestTemplate restTemplate = new RestTemplate();
            HttpHeaders headers = new HttpHeaders();
            headers.set("User-Agent",
                    "SmartDeliverySystem/1.0 contact@example.com");
            headers.set("Accept-Language", "en");
            HttpEntity<String> entity =
                    new HttpEntity<>(headers);

            ResponseEntity<String> response =
                    restTemplate.exchange(
                            url, HttpMethod.GET,
                            entity, String.class);

            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(
                    response.getBody());

            if (root.isArray() && root.size() > 0) {
                double lat = root.get(0).get("lat").asDouble();
                double lon = root.get(0).get("lon").asDouble();
                System.out.println(level + " success: "
                        + lat + ", " + lon);
                return new double[]{lat, lon};
            }
        } catch (Exception e) {
            System.out.println(level + " error: "
                    + e.getMessage());
        }
        return null;
    }
}