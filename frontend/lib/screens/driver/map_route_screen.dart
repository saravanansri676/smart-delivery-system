import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/weather_service.dart';

class MapRouteScreen extends StatefulWidget {
  final String driverId;
  const MapRouteScreen({super.key, required this.driverId});

  @override
  State<MapRouteScreen> createState() => _MapRouteScreenState();
}

class _MapRouteScreenState extends State<MapRouteScreen> {
  List route = [];
  bool isLoading = true;
  String weatherWarning = '';
  String weatherIcon = '🌤';
  Map weatherData = {};

  final String baseUrl = 'http://10.0.2.2:8080';
  final WeatherService weatherService = WeatherService();

  // Driver start location - Chennai
  final LatLng startLocation = const LatLng(13.0827, 80.2707);

  @override
  void initState() {
    super.initState();
    fetchRouteAndWeather();
  }

  Future<void> fetchRouteAndWeather() async {
    try {
      // Fetch optimized route from backend
      final response = await http.get(Uri.parse(
          '$baseUrl/route/optimize/${widget.driverId}'
              '?startLat=13.0827&startLon=80.2707'));

      if (response.statusCode == 200) {
        final routeData = jsonDecode(response.body);

        // Fetch weather for start location
        final weather = await weatherService.getWeather(
            13.0827, 80.2707);

        setState(() {
          route = routeData;
          weatherData = weather;
          weatherWarning =
              weatherService.getWeatherWarning(weather);
          weatherIcon = weatherService.getWeatherIcon(weather);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // Build route points for map line
  List<LatLng> getRoutePoints() {
    List<LatLng> points = [startLocation];
    for (var pkg in route) {
      points.add(LatLng(
        pkg['latitude'].toDouble(),
        pkg['longitude'].toDouble(),
      ));
    }
    return points;
  }

  // Build markers for each stop
  List<Marker> getMarkers() {
    List<Marker> markers = [];

    // Start marker
    markers.add(Marker(
      point: startLocation,
      width: 40,
      height: 40,
      child: const Icon(
        Icons.warehouse,
        color: Colors.blue,
        size: 35,
      ),
    ));

    // Package stop markers
    for (int i = 0; i < route.length; i++) {
      final pkg = route[i];
      markers.add(Marker(
        point: LatLng(
          pkg['latitude'].toDouble(),
          pkg['longitude'].toDouble(),
        ),
        width: 40,
        height: 50,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: const Color(0xFF1565C0),
                shape: BoxShape.circle,
                border: Border.all(
                    color: Colors.white, width: 2),
              ),
              child: Text(
                '${i + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const Icon(Icons.location_pin,
                color: Colors.red, size: 20),
          ],
        ),
      ));
    }

    return markers;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Text('🔄',
                style: TextStyle(fontSize: 20)),
            onPressed: fetchRouteAndWeather,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // Weather warning banner
          if (weatherWarning.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: weatherService
                  .isDangerousWeather(
                  weatherData as Map<String,
                      dynamic>)
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              child: Row(
                children: [
                  Text(weatherIcon,
                      style:
                      const TextStyle(fontSize: 24)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      weatherWarning,
                      style: TextStyle(
                        fontSize: 13,
                        color: weatherService
                            .isDangerousWeather(
                            weatherData
                            as Map<String,
                                dynamic>)
                            ? Colors.red.shade800
                            : Colors.green.shade800,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Map
          Expanded(
            flex: 3,
            child: FlutterMap(
              options: MapOptions(
                initialCenter: startLocation,
                initialZoom: 11,
              ),
              children: [
                // OpenStreetMap tile layer
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org'
                      '/{z}/{x}/{y}.png',
                  userAgentPackageName:
                  'com.example.smart_delivery_app',
                ),
                // Route line
                if (route.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: getRoutePoints(),
                        strokeWidth: 4,
                        color: const Color(0xFF1565C0),
                      ),
                    ],
                  ),
                // Stop markers
                MarkerLayer(markers: getMarkers()),
              ],
            ),
          ),

          // Stop list
          Expanded(
            flex: 2,
            child: route.isEmpty
                ? const Center(
                child: Text('No packages assigned'))
                : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: route.length,
              itemBuilder: (context, index) {
                final pkg = route[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    const Color(0xFF1565C0),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                          color: Colors.white),
                    ),
                  ),
                  title:
                  Text(pkg['packageName'] ?? ''),
                  subtitle: Text(
                      '${pkg['address']} • '
                          'Deadline: ${pkg['deadline']}'),
                  dense: true,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}