package com.example.demo.service;

import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;

@Service
public class GeocodingService {

    // Using OpenStreetMap Nominatim API (free, no key needed)
    private static final String NOMINATIM_URL =
            "https://nominatim.openstreetmap.org/search"
                    + "?q={address}&format=json&limit=1";

    public double[] getCoordinates(String address) {
        try {
            RestTemplate restTemplate = new RestTemplate();

            // Add required User-Agent header
            org.springframework.http.HttpHeaders headers =
                    new org.springframework.http.HttpHeaders();
            headers.set("User-Agent",
                    "SmartDeliverySystem/1.0");

            org.springframework.http.HttpEntity<String> entity =
                    new org.springframework.http.HttpEntity<>(headers);

            String url = "https://nominatim.openstreetmap.org"
                    + "/search?q="
                    + address.replace(" ", "+")
                    + "&format=json&limit=1";

            org.springframework.http.ResponseEntity<String> response =
                    restTemplate.exchange(
                            url,
                            org.springframework.http.HttpMethod.GET,
                            entity,
                            String.class
                    );

            ObjectMapper mapper = new ObjectMapper();
            JsonNode root = mapper.readTree(response.getBody());

            if (root.isArray() && root.size() > 0) {
                double lat = root.get(0)
                        .get("lat").asDouble();
                double lon = root.get(0)
                        .get("lon").asDouble();
                return new double[]{lat, lon};
            }
        } catch (Exception e) {
            System.out.println(
                    "Geocoding error: " + e.getMessage());
        }

        // Default to Chennai if geocoding fails
        return new double[]{13.0827, 80.2707};
    }
}
