import 'package:flutter/material.dart';
import 'view_route_screen.dart';

class RouteTypeScreen extends StatefulWidget {
  final String driverId;
  final String managerId;

  const RouteTypeScreen({
    super.key,
    required this.driverId,
    required this.managerId,
  });

  @override
  State<RouteTypeScreen> createState() =>
      _RouteTypeScreenState();
}

class _RouteTypeScreenState
    extends State<RouteTypeScreen> {
  String? _selectedType;

  final List<Map<String, dynamic>> _routeTypes = [
    {
      'value': 'SHORTEST',
      'label': 'Shortest Route',
      'description':
      'Optimized for minimum total distance',
      'icon': Icons.straighten_rounded,
      'color': const Color(0xFF0D47A1),
    },
    {
      'value': 'TRAFFIC_LESS',
      'label': 'Traffic Less Route',
      'description':
      'Avoids roads with known congestion '
          'based on your history',
      'icon': Icons.traffic_rounded,
      'color': const Color(0xFF2E7D32),
    },
    {
      'value': 'WEATHER_GOOD',
      'label': 'Weather Good Route',
      'description':
      'Prefers roads with clear weather conditions',
      'icon': Icons.wb_sunny_rounded,
      'color': const Color(0xFFE65100),
    },
    {
      'value': 'PETROL_BUNK',
      'label': 'Petrol Bunk Near',
      'description':
      'Route passes near a fuel station — '
          'useful when fuel is low',
      'icon': Icons.local_gas_station_rounded,
      'color': const Color(0xFF6A1B9A),
    },
  ];

  void _proceed() {
    if (_selectedType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
          const Text('Please select a route type'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    // Navigate to route list with selected type
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ViewRouteScreen(
          driverId: widget.driverId,
          managerId: widget.managerId,
          routeType: _selectedType!,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Select Route Type'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0D47A1),
                  Color(0xFF1976D2)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                const Text(
                  'How do you want to deliver?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Choose a route strategy that '
                      'suits your current situation.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.8),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Route options
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _routeTypes.length,
              itemBuilder: (context, index) {
                final type = _routeTypes[index];
                final isSelected =
                    _selectedType == type['value'];
                final color = type['color'] as Color;

                return GestureDetector(
                  onTap: () => setState(
                          () => _selectedType =
                      type['value']),
                  child: AnimatedContainer(
                    duration: const Duration(
                        milliseconds: 200),
                    margin: const EdgeInsets.only(
                        bottom: 12),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withOpacity(0.07)
                          : Colors.white,
                      borderRadius:
                      BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? color.withOpacity(0.15)
                              : Colors.grey
                              .withOpacity(0.07),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        // Icon box
                        Container(
                          padding:
                          const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color
                                .withOpacity(0.1),
                            borderRadius:
                            BorderRadius.circular(
                                12),
                          ),
                          child: Icon(
                            type['icon'] as IconData,
                            color: color,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),

                        // Text
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                            CrossAxisAlignment.start,
                            children: [
                              Text(
                                type['label'] as String,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight:
                                  FontWeight.w700,
                                  color: isSelected
                                      ? color
                                      : const Color(
                                      0xFF1A1A2E),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                type['description']
                                as String,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors
                                      .grey.shade500,
                                  height: 1.4,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),

                        // Radio indicator
                        AnimatedContainer(
                          duration: const Duration(
                              milliseconds: 200),
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? color
                                : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.grey.shade400,
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 14,
                          )
                              : null,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Next button
          Container(
            padding: const EdgeInsets.fromLTRB(
                16, 12, 16, 28),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.15),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _proceed,
                icon: const Icon(
                    Icons.arrow_forward_rounded),
                label: const Text(
                  'Next',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}