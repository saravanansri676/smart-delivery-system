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
  final String routeType;

  const MapRouteScreen({
    super.key,
    required this.driverId,
    required this.managerId,
    this.routeType = 'SHORTEST',
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
  String weatherIcon = ' ';
  Map weatherData = {};

  List<LatLng> roadPolylinePoints = [];

  LatLng _startLocation = LatLng(
      DepotService.defaultLat,
      DepotService.defaultLon);

  final String baseUrl = 'http://10.0.2.2:8080';
  final WeatherService weatherService =
  WeatherService();

  static const String osrmBase =
      'http://router.project-osrm.org/route/v1/driving';

  @override
  void initState() {
    super.initState();
    _loadWithDepot();
  }

  Future<void> _loadWithDepot() async {
    final coords = await DepotService.getDepotCoords(
        widget.managerId);
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

      String endpoint;
      switch (widget.routeType) {
        case 'TRAFFIC_LESS':
          endpoint =
          '$baseUrl/behavior/route/${widget.driverId}'
              '?startLat=$lat&startLon=$lon';
          break;
        case 'PETROL_BUNK':
        case 'WEATHER_GOOD':
        case 'SHORTEST':
        default:
          endpoint =
          '$baseUrl/route/optimize/${widget.driverId}'
              '?startLat=$lat&startLon=$lon';
          break;
      }

      final response =
      await http.get(Uri.parse(endpoint));

      if (response.statusCode == 200) {
        final routeData = jsonDecode(response.body);
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

        if (routeData.isNotEmpty) {
          await _fetchRoadRoute();
        }
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ── Fetch road route from OSRM ───────────────────────────
  // Route: Depot → Stop1 → Stop2 → ... → LastStop → Depot
  // The depot is added as BOTH the first AND last point
  // so driver knows how to return home.
  Future<void> _fetchRoadRoute() async {
    if (route.isEmpty) return;
    setState(() => isLoadingRoute = true);

    try {
      final StringBuffer coords = StringBuffer();

      // Start: depot
      coords.write(
          '${_startLocation.longitude},'
              '${_startLocation.latitude}');

      // All delivery stops
      for (final pkg in route) {
        final lat =
        (pkg['latitude'] as num).toDouble();
        final lon =
        (pkg['longitude'] as num).toDouble();
        coords.write(';$lon,$lat');
      }

      //  End: depot again (return trip)
      coords.write(
          ';${_startLocation.longitude},'
              '${_startLocation.latitude}');

      final url =
          '$osrmBase/${coords.toString()}'
          '?overview=full&geometries=geojson'
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
          setState(() {
            roadPolylinePoints =
                _straightLinePoints();
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
      setState(() {
        roadPolylinePoints = _straightLinePoints();
        isLoadingRoute = false;
      });
    }
  }

  // Fallback straight lines — also includes return to depot
  List<LatLng> _straightLinePoints() {
    final List<LatLng> points = [_startLocation];
    for (final pkg in route) {
      points.add(LatLng(
        (pkg['latitude'] as num).toDouble(),
        (pkg['longitude'] as num).toDouble(),
      ));
    }
    // Return to depot
    points.add(_startLocation);
    return points;
  }

  Color get _routeColor {
    switch (widget.routeType) {
      case 'TRAFFIC_LESS':
        return const Color(0xFF2E7D32);
      case 'WEATHER_GOOD':
        return const Color(0xFFE65100);
      case 'PETROL_BUNK':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF1565C0);
    }
  }

  String get _routeTypeLabel {
    switch (widget.routeType) {
      case 'TRAFFIC_LESS':
        return 'Traffic Less Route';
      case 'WEATHER_GOOD':
        return 'Weather Good Route';
      case 'PETROL_BUNK':
        return 'Via Petrol Bunk';
      default:
        return 'Shortest Route';
    }
  }

  List<Marker> getMarkers() {
    List<Marker> markers = [];

    // Depot marker (start)
    markers.add(Marker(
      point: _startLocation,
      width: 48,
      height: 48,
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
          size: 24,
        ),
      ),
    ));

    // Delivery stop markers
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
            color: _routeColor,
            shape: BoxShape.circle,
            border: Border.all(
                color: Colors.white, width: 2),
            boxShadow: [
              BoxShadow(
                color: _routeColor.withOpacity(0.4),
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
          icon:
          const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(
                vertical: 10, horizontal: 4),
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _routeTypeLabel,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
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
              color: weatherService
                  .isDangerousWeather(
                  weatherData as Map<
                      String, dynamic>)
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
                            as Map<
                                String,
                                dynamic>)
                            ? Colors.red.shade800
                            : Colors
                            .green.shade800,
                        fontWeight:
                        FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Road loading banner
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
                    child:
                    CircularProgressIndicator(
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
                TileLayer(
                  urlTemplate:
                  'https://tile.openstreetmap.org'
                      '/{z}/{x}/{y}.png',
                  userAgentPackageName:
                  'com.example.smart_delivery_app',
                ),
                if (roadPolylinePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: roadPolylinePoints,
                        strokeWidth: 4.5,
                        color: _routeColor,
                      ),
                    ],
                  )
                else if (route.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points:
                        _straightLinePoints(),
                        strokeWidth: 1.5,
                        color:
                        Colors.grey.shade400,
                      ),
                    ],
                  ),
                MarkerLayer(
                    markers: getMarkers()),
              ],
            ),
          ),

          // Stop list — includes return to depot
          Expanded(
            flex: 2,
            child: route.isEmpty
                ? const Center(
                child: Text(
                    'No packages assigned'))
                : ListView.builder(
              padding:
              const EdgeInsets.all(8),
              // +1 for the return to depot row
              itemCount: route.length + 1,
              itemBuilder:
                  (context, index) {
                // Last item = return to depot
                if (index == route.length) {
                  return ListTile(
                    leading: Container(
                      width: 36,
                      height: 36,
                      decoration:
                      BoxDecoration(
                        color: Colors
                            .blue.shade700,
                        shape:
                        BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons
                            .warehouse_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                    title: const Text(
                      'Return to Depot',
                      style: TextStyle(
                        fontWeight:
                        FontWeight.w700,
                        color: Color(
                            0xFF1565C0),
                      ),
                    ),
                    subtitle: const Text(
                      'End of delivery route',
                      style: TextStyle(
                          fontSize: 12),
                    ),
                    dense: true,
                  );
                }

                final pkg = route[index];
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    _routeColor,
                    child: Text(
                      '${index + 1}',
                      style:
                      const TextStyle(
                        color: Colors.white,
                        fontWeight:
                        FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    pkg['packageName'] ??
                        '',
                    style: const TextStyle(
                        fontWeight:
                        FontWeight.w600),
                  ),
                  subtitle: Text(
                    '${pkg['address']} • '
                        'Deadline: ${pkg['deadline']}',
                    maxLines: 2,
                    overflow: TextOverflow
                        .ellipsis,
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