import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/depot_service.dart';
import 'map_route_screen.dart';

class ViewRouteScreen extends StatefulWidget {
  final String driverId;
  final String managerId;
  final String routeType;

  const ViewRouteScreen({
    super.key,
    required this.driverId,
    required this.managerId,
    this.routeType = 'SHORTEST',
  });

  @override
  State<ViewRouteScreen> createState() =>
      _ViewRouteScreenState();
}

class _ViewRouteScreenState
    extends State<ViewRouteScreen> {
  List route = [];
  bool isLoading = true;
  double _startLat = DepotService.defaultLat;
  double _startLon = DepotService.defaultLon;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _loadWithDepot();
  }

  Future<void> _loadWithDepot() async {
    final coords = await DepotService.getDepotCoords(
        widget.managerId);
    setState(() {
      _startLat = coords[0];
      _startLon = coords[1];
    });
    await fetchRoute();
  }

  // ── Fetch route based on selected type ──────────────────
  Future<void> fetchRoute() async {
    setState(() => isLoading = true);
    try {
      String endpoint;

      switch (widget.routeType) {
        case 'TRAFFIC_LESS':
          endpoint =
          '$baseUrl/behavior/route/${widget.driverId}'
              '?startLat=$_startLat'
              '&startLon=$_startLon';
          break;
        case 'PETROL_BUNK':
        case 'WEATHER_GOOD':
        case 'SHORTEST':
        default:
          endpoint =
          '$baseUrl/route/optimize/${widget.driverId}'
              '?startLat=$_startLat'
              '&startLon=$_startLon';
          break;
      }

      final response =
      await http.get(Uri.parse(endpoint));
      if (response.statusCode == 200) {
        setState(() {
          route = jsonDecode(response.body);
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> markDelivered(String packageId) async {
    try {
      final response = await http.put(Uri.parse(
          '$baseUrl/reroute/delivered/$packageId'
              '?driverId=${widget.driverId}'
              '&currentLat=$_startLat'
              '&currentLon=$_startLon'));

      if (response.statusCode == 200) {
        final result = response.body;

        if (result == 'ALL_DELIVERED') {
          _showAllDeliveredDialog();
        } else if (result.startsWith('NEXT:')) {
          final parts =
          result.substring(5).split('|');
          final address =
          parts.isNotEmpty ? parts[0] : '';
          final name =
          parts.length > 1 ? parts[1] : '';
          final deadline =
          parts.length > 2 ? parts[2] : '';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text('✅ Package Delivered!',
                      style: TextStyle(
                          fontWeight:
                          FontWeight.w700)),
                  Text(
                      'Next: $name — $address'
                          ' (Deadline: $deadline)',
                      style: const TextStyle(
                          fontSize: 12)),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10)),
            ),
          );
          fetchRoute();
        } else {
          fetchRoute();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
          Text('Connection error. Try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showAllDeliveredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🎉',
                  style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'All Delivered!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'Great job! All packages '
                          'delivered successfully.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32)
                            .withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.circle,
                              color:
                              Color(0xFF2E7D32),
                              size: 10),
                          SizedBox(width: 6),
                          Text(
                            'Your status is now AVAILABLE',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2E7D32),
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    fetchRoute();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done — Great Job! 🚀',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String get _routeTypeLabel {
    switch (widget.routeType) {
      case 'TRAFFIC_LESS':
        return 'Traffic Less';
      case 'WEATHER_GOOD':
        return 'Weather Good';
      case 'PETROL_BUNK':
        return 'Via Petrol Bunk';
      default:
        return 'Shortest';
    }
  }

  Color get _routeTypeColor {
    switch (widget.routeType) {
      case 'TRAFFIC_LESS':
        return const Color(0xFF2E7D32);
      case 'WEATHER_GOOD':
        return const Color(0xFFE65100);
      case 'PETROL_BUNK':
        return const Color(0xFF6A1B9A);
      default:
        return const Color(0xFF0D47A1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Route'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Route type badge
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
            onPressed: fetchRoute,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator())
          : route.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
                Icons
                    .check_circle_outline_rounded,
                size: 72,
                color:
                Colors.green.shade300),
            const SizedBox(height: 16),
            const Text(
              'No packages assigned',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey),
            ),
          ],
        ),
      )
          : Column(
        children: [
          // Route type + View Map button bar
          Container(
            width: double.infinity,
            padding:
            const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 10),
            color: _routeTypeColor
                .withOpacity(0.08),
            child: Row(
              children: [
                Icon(Icons.route_rounded,
                    color: _routeTypeColor,
                    size: 16),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    '$_routeTypeLabel route • '
                        '${route.length} stop'
                        '${route.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: 12,
                      color: _routeTypeColor,
                      fontWeight:
                      FontWeight.w600,
                    ),
                  ),
                ),

                // ✅ View Map button
                GestureDetector(
                  onTap: () =>
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              MapRouteScreen(
                                driverId:
                                widget.driverId,
                                managerId:
                                widget.managerId,
                                routeType:
                                widget.routeType,
                              ),
                        ),
                      ),
                  child: Container(
                    padding:
                    const EdgeInsets
                        .symmetric(
                        horizontal: 12,
                        vertical: 6),
                    decoration: BoxDecoration(
                      color: _routeTypeColor,
                      borderRadius:
                      BorderRadius
                          .circular(20),
                    ),
                    child: const Row(
                      mainAxisSize:
                      MainAxisSize.min,
                      children: [
                        Icon(
                            Icons.map_rounded,
                            color:
                            Colors.white,
                            size: 14),
                        SizedBox(width: 4),
                        Text(
                          'View Map',
                          style: TextStyle(
                            color:
                            Colors.white,
                            fontSize: 12,
                            fontWeight:
                            FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Route list
          Expanded(
            child: ListView.builder(
              padding:
              const EdgeInsets.all(16),
              itemCount: route.length,
              itemBuilder: (context, index) {
                final pkg = route[index];
                return Card(
                  margin:
                  const EdgeInsets.only(
                      bottom: 12),
                  shape:
                  RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                        12),
                  ),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor:
                      const Color(
                          0xFF1565C0),
                      child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                              color:
                              Colors.white,
                              fontWeight:
                              FontWeight
                                  .bold)),
                    ),
                    title: Text(
                      pkg['packageName'] ??
                          '',
                      style: const TextStyle(
                          fontWeight:
                          FontWeight.w600),
                    ),
                    subtitle: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment
                          .start,
                      children: [
                        Text(
                          pkg['address'] ??
                              '',
                          maxLines: 2,
                          overflow:
                          TextOverflow
                              .ellipsis,
                        ),
                        Text(
                          'Deadline: ${pkg['deadline']}',
                          style:
                          const TextStyle(
                            color: Color(
                                0xFF1565C0),
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing:
                    ElevatedButton(
                      onPressed: () =>
                          markDelivered(
                              pkg['packageId']),
                      style: ElevatedButton
                          .styleFrom(
                        backgroundColor:
                        Colors.green,
                        foregroundColor:
                        Colors.white,
                        padding:
                        const EdgeInsets
                            .symmetric(
                            horizontal:
                            12,
                            vertical: 8),
                        shape:
                        RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius
                              .circular(
                              8),
                        ),
                      ),
                      child: const Text(
                          'Done'),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}