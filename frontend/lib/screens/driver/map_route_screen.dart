import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/weather_service.dart';
import '../../services/depot_service.dart';

class MapRouteScreen extends StatefulWidget {
  final String driverId;
  final String managerId;

  const MapRouteScreen({
    super.key,
    required this.driverId,
    required this.managerId,
  });

  @override
  State<MapRouteScreen> createState() =>
      _MapRouteScreenState();
}

class _MapRouteScreenState
    extends State<MapRouteScreen> {
  List route = [];
  bool isLoading = true;
  bool isLoadingRoute = false;
  String weatherWarning = '';
  String weatherIcon = '🌤';
  Map weatherData = {};

  // Road-following polyline points from OSRM
  List<LatLng> roadPolylinePoints = [];

  LatLng _startLocation = LatLng(
      DepotService.defaultLat, DepotService.defaultLon);

  final String baseUrl = 'http://10.0.2.2:8080';
  final WeatherService weatherService = WeatherService();

  // OSRM public API — free, no key needed
  static const String osrmBase =
      'http://router.project-osrm.org/route/v1/driving';

  @override
  void initState() {
    super.initState();
    _loadWithDepot();
  }

  Future<void> _loadWithDepot() async {
    final coords =
    await DepotService.getDepotCoords(widget.managerId);
    setState(() {
      _startLocation = LatLng(coords[0], coords[1]);
    });
    await fetchRouteAndWeather();
  }

  Future<void> fetchRouteAndWeather() async {
    setState(() => isLoading = true);
    try {
      final lat = _startLocation.latitude;
      final lon = _startLocation.longitude;

      // 1. Fetch optimized stop order from backend
      final response = await http.get(Uri.parse(
          '$baseUrl/route/optimize/${widget.driverId}'
              '?startLat=$lat&startLon=$lon'));

      if (response.statusCode == 200) {
        final routeData = jsonDecode(response.body);

        // 2. Fetch weather
        final weather =
        await weatherService.getWeather(lat, lon);

        setState(() {
          route = routeData;
          weatherData = weather;
          weatherWarning =
              weatherService.getWeatherWarning(weather);
          weatherIcon =
              weatherService.getWeatherIcon(weather);
          isLoading = false;
        });

        // 3. Fetch road-following route from OSRM
        if (routeData.isNotEmpty) {
          await _fetchRoadRoute();
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ── Fetch road-following route from OSRM ────────────────
  Future<void> _fetchRoadRoute() async {
    if (route.isEmpty) return;

    setState(() => isLoadingRoute = true);

    try {
      // Build coordinate string: lon,lat;lon,lat;...
      // OSRM uses longitude FIRST then latitude
      final StringBuffer coords = StringBuffer();

      // Start: depot location
      coords.write(
          '${_startLocation.longitude},'
              '${_startLocation.latitude}');

      // Each delivery stop
      for (final pkg in route) {
        final lat =
        (pkg['latitude'] as num).toDouble();
        final lon =
        (pkg['longitude'] as num).toDouble();
        coords.write(';$lon,$lat');
      }

      final url = '$osrmBase/${coords.toString()}'
          '?overview=full'
          '&geometries=geojson'
          '&steps=false';

      final response = await http
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data['code'] == 'Ok' &&
            data['routes'] != null &&
            (data['routes'] as List).isNotEmpty) {

          final geometry =
          data['routes'][0]['geometry'];
          final coordinates =
          geometry['coordinates'] as List;

          // Convert [lon, lat] pairs to LatLng
          final List<LatLng> points = coordinates
              .map<LatLng>((c) => LatLng(
            (c[1] as num).toDouble(),
            (c[0] as num).toDouble(),
          ))
              .toList();

          setState(() {
            roadPolylinePoints = points;
            isLoadingRoute = false;
          });
        } else {
          // OSRM returned error — fallback
          setState(() {
            roadPolylinePoints = _straightLinePoints();
            isLoadingRoute = false;
          });
        }
      } else {
        setState(() {
          roadPolylinePoints = _straightLinePoints();
          isLoadingRoute = false;
        });
      }
    } catch (e) {
      // Network error or timeout — use straight lines
      debugPrint('OSRM error: $e');
      setState(() {
        roadPolylinePoints = _straightLinePoints();
        isLoadingRoute = false;
      });
    }
  }

  // Fallback: straight lines if OSRM fails
  List<LatLng> _straightLinePoints() {
    final List<LatLng> points = [_startLocation];
    for (final pkg in route) {
      points.add(LatLng(
        (pkg['latitude'] as num).toDouble(),
        (pkg['longitude'] as num).toDouble(),
      ));
    }
    return points;
  }

  // ── Markers ──────────────────────────────────────────────
  List<Marker> getMarkers() {
    List<Marker> markers = [];

    // Depot marker
    markers.add(Marker(
      point: _startLocation,
      width: 44,
      height: 44,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade700,
          shape: BoxShape.circle,
          border:
          Border.all(color: Colors.white, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.blue.withOpacity(0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: const Icon(
          Icons.warehouse_rounded,
          color: Colors.white,
          size: 22,
        ),
      ),
    ));

    // Stop markers
    for (int i = 0; i < route.length; i++) {
      final pkg = route[i];
      markers.add(Marker(
        point: LatLng(
          (pkg['latitude'] as num).toDouble(),
          (pkg['longitude'] as num).toDouble(),
        ),
        width: 36,
        height: 36,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1),
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0D47A1)
                    .withOpacity(0.4),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: Text(
              '${i + 1}',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: fetchRouteAndWeather,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator())
          : Column(
        children: [
          // Weather banner
          if (weatherWarning.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              color: weatherService.isDangerousWeather(
                  weatherData
                  as Map<String, dynamic>)
                  ? Colors.red.shade100
                  : Colors.green.shade100,
              child: Row(
                children: [
                  Text(weatherIcon,
                      style: const TextStyle(
                          fontSize: 24)),
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

          // Road route loading banner
          if (isLoadingRoute)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  vertical: 6),
              color: Colors.blue.shade50,
              child: Row(
                mainAxisAlignment:
                MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.blue.shade700,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Loading road route...',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue.shade700,
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
                initialCenter: _startLocation,
                initialZoom: 12,
              ),
              children: [
                // OpenStreetMap tiles
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org'
                      '/{z}/{x}/{y}.png',
                  userAgentPackageName:
                  'com.example.smart_delivery_app',
                ),

                // ✅ Road-following polyline from OSRM
                // Shows thin grey line while loading,
                // replaces with thick blue road line
                // once OSRM responds
                if (roadPolylinePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: roadPolylinePoints,
                        strokeWidth: 4.5,
                        color:
                        const Color(0xFF1565C0),
                      ),
                    ],
                  )
                // Thin grey fallback while loading
                else if (route.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points:
                        _straightLinePoints(),
                        strokeWidth: 1.5,
                        color: Colors.grey.shade400,
                      ),
                    ],
                  ),

                // Markers on top
                MarkerLayer(
                    markers: getMarkers()),
              ],
            ),
          ),

          // Stop list
          Expanded(
            flex: 2,
            child: route.isEmpty
                ? const Center(
                child: Text(
                    'No packages assigned'))
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
                        color: Colors.white,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    pkg['packageName'] ?? '',
                    style: const TextStyle(
                        fontWeight:
                        FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${pkg['address']} • '
                        'Deadline: ${pkg['deadline']}',
                    maxLines: 2,
                    overflow:
                    TextOverflow.ellipsis,
                  ),
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