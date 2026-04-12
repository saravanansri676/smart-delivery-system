-- Seed fuel stations into DB on startup
-- Place this file at: src/main/resources/data.sql
-- Spring Boot auto-runs this on startup when using H2 or
-- when spring.sql.init.mode=always in application.properties

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('IOC Gandhipuram', 'Indian Oil', 11.0168, 76.9674, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES('IOC RS Puram', 'Indian Oil', 11.0089, 76.9513, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('IOC Peelamedu', 'Indian Oil', 11.0293, 77.0267, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('IOC Singanallur', 'Indian Oil', 11.0010, 77.0217, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('IOC Ukkadam', 'Indian Oil', 10.9985, 76.9600, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('BP Saibaba Colony', 'Bharat Petroleum', 11.0283, 76.9515, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('BP Vadavalli', 'Bharat Petroleum', 11.0250, 76.9060, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('BP Saravanampatti', 'Bharat Petroleum', 11.0797, 77.0020, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('BP Kuniyamuthur', 'Bharat Petroleum', 10.9635, 76.9550, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('HP Avinashi Road', 'Hindustan Petroleum', 11.0400, 77.0400, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('HP Ganapathy', 'Hindustan Petroleum', 11.0450, 76.9900, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('HP Mettupalayam Road', 'Hindustan Petroleum', 11.0300, 76.9500, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('Shell Avinashi Road', 'Shell', 11.0350, 77.0300, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;

INSERT INTO fuel_stations (name, provider, latitude, longitude, city, active)
VALUES ('Nayara Energy Neelambur', 'Nayara Energy', 11.0900, 77.0900, 'Coimbatore', true)
    ON CONFLICT DO NOTHING;