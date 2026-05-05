import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'packages_screen.dart';
import 'vehicle_details_screen.dart';
import 'report_incident_screen.dart';
import 'weather_screen.dart';
import 'driver_profile_screen.dart';
import 'notifications_screen.dart';
import '../../services/work_hour_service.dart';

class DriverHome extends StatefulWidget {
  final String driverIdFromLogin;
  final String driverName;
  final String managerId;

  const DriverHome({
    super.key,
    required this.driverIdFromLogin,
    this.driverName = '',
    this.managerId = '',
  });

  @override
  State<DriverHome> createState() =>
      _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  late final WorkHourService _workHourService;
  Timer? _notificationTimer;
  int _unreadCount = 0;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();

    // Start work hour monitoring — auto OFFLINE at 16:00
    _workHourService = WorkHourService(
      driverId: widget.driverIdFromLogin,
      workEndTime: '16:00',
      onStatusChanged: (newStatus) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '🕓 Work hours ended. '
                    'Your status is now $newStatus.',
              ),
              backgroundColor: Colors.orange.shade700,
              duration: const Duration(seconds: 5),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      },
    );
    _workHourService.start();

    // Poll unread notification count every 30s
    _fetchUnreadCount();
    _notificationTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _fetchUnreadCount(),
    );
  }

  @override
  void dispose() {
    _workHourService.stop();
    _notificationTimer?.cancel();
    super.dispose();
  }

  Future<void> _fetchUnreadCount() async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/notifications'
              '/${widget.driverIdFromLogin}'
              '/unread-count'));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _unreadCount =
              (data['count'] as num).toInt();
        });
      }
    } catch (e) {
      debugPrint('Notification count error: $e');
    }
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => screen,
        transitionsBuilder: (_, a, b, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: a, curve: Curves.easeOut)),
              child: child,
            ),
        transitionDuration:
        const Duration(milliseconds: 300),
      ),
    ).then((_) => _fetchUnreadCount());
  }

  @override
  Widget build(BuildContext context) {
    final String driverId = widget.driverIdFromLogin;

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          // Notifications bell with badge
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                  Icons.notifications_outlined,
                  color: Colors.white,
                  size: 26,
                ),
                onPressed: () => _navigate(
                  context,
                  NotificationsScreen(
                      driverId: driverId),
                ),
              ),
              if (_unreadCount > 0)
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      _unreadCount > 9
                          ? '9+'
                          : '$_unreadCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),

          // Profile icon
          IconButton(
            icon: const Icon(
              Icons.account_circle_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => _navigate(
              context,
              DriverProfileScreen(driverId: driverId),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1B5E20),
                    Color(0xFF388E3C)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20)
                        .withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color:
                      Colors.white.withOpacity(0.2),
                      borderRadius:
                      BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.drive_eta_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.driverName.isNotEmpty
                              ? 'Hello, ${widget.driverName}!'
                              : 'Hello, Driver!',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          driverId,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Text(
                          'Smart Delivery System',
                          style: TextStyle(
                            color: Colors.white54,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            const Text(
              'QUICK ACTIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // 4 action cards
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                // 1. Packages
                _buildMenuCard(
                  context,
                  icon: Icons.inventory_2_rounded,
                  title: 'Packages',
                  subtitle: 'View assigned packages',
                  color: const Color(0xFF0D47A1),
                  onTap: () => _navigate(
                    context,
                    PackagesScreen(driverId: driverId),
                  ),
                ),

                // 2. My Route
                // ✅ Opens VehicleDetailsScreen FIRST
                // then RouteTypeScreen
                // then ViewRouteScreen
                _buildMenuCard(
                  context,
                  icon: Icons.route_rounded,
                  title: 'My Route',
                  subtitle: 'View delivery stops',
                  color: const Color(0xFF2E7D32),
                  onTap: () => _navigate(
                    context,
                    VehicleDetailsScreen(
                      driverId: driverId,
                      managerId: widget.managerId,
                    ),
                  ),
                ),

                // 3. Weather
                _buildMenuCard(
                  context,
                  icon: Icons.cloud_rounded,
                  title: 'Weather',
                  subtitle: 'Current condition',
                  color: const Color(0xFF1565C0),
                  onTap: () => _navigate(
                    context,
                    const WeatherScreen(
                      latitude: 11.0168,
                      longitude: 76.9674,
                    ),
                  ),
                ),

                // 4. Report Issue
                _buildMenuCard(
                  context,
                  icon: Icons.warning_rounded,
                  title: 'Report Issue',
                  subtitle: 'Vehicle incidents',
                  color: const Color(0xFFC62828),
                  onTap: () => _navigate(
                    context,
                    ReportIncidentScreen(
                        driverId: driverId),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(
      BuildContext context, {
        required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}