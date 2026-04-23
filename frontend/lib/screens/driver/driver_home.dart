import 'package:flutter/material.dart';
import 'view_route_screen.dart';
import 'fuel_status_screen.dart';
import 'report_incident_screen.dart';
import 'map_route_screen.dart';
import 'weather_screen.dart';
import 'driver_profile_screen.dart';
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
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  late final WorkHourService _workHourService;

  @override
  void initState() {
    super.initState();

    // Start work hour monitoring
    // Automatically sets driver OFFLINE at 16:00
    _workHourService = WorkHourService(
      driverId: widget.driverIdFromLogin,
      workEndTime: '16:00',
      onStatusChanged: (newStatus) {
        // Show snackbar when auto-offline triggers
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
  }

  @override
  void dispose() {
    // Stop timer when driver leaves the dashboard
    _workHourService.stop();
    super.dispose();
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
          IconButton(
            icon: const Icon(
              Icons.account_circle_rounded,
              color: Colors.white,
              size: 28,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DriverProfileScreen(
                    driverId: driverId),
              ),
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
                      color: Colors.white.withOpacity(0.2),
                      borderRadius:
                      BorderRadius.circular(12),
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
                            fontSize: 14,
                            fontFamily: 'monospace',
                          ),
                        ),
                        const Text(
                          'Smart Delivery System',
                          style: TextStyle(
                            color: Colors.white60,
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

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildMenuCard(
                  context,
                  icon: Icons.route_rounded,
                  title: 'My Route',
                  subtitle: 'View delivery stops',
                  color: const Color(0xFF2E7D32),
                  onTap: () => _navigate(
                    context,
                    ViewRouteScreen(
                      driverId: driverId,
                      managerId: widget.managerId,
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.map_rounded,
                  title: 'Route Map',
                  subtitle: 'Visual navigation',
                  color: const Color(0xFF00838F),
                  onTap: () => _navigate(
                    context,
                    MapRouteScreen(
                      driverId: driverId,
                      managerId: widget.managerId,
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.cloud_rounded,
                  title: 'Weather',
                  subtitle: 'Current conditions',
                  color: const Color(0xFF1565C0),
                  onTap: () => _navigate(
                    context,
                    const WeatherScreen(
                      latitude: 11.0168,
                      longitude: 76.9674,
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.local_gas_station_rounded,
                  title: 'Fuel Status',
                  subtitle: 'Check & update fuel',
                  color: const Color(0xFFE65100),
                  onTap: () => _navigate(
                    context,
                    FuelStatusScreen(
                      driverId: driverId,
                      managerId: widget.managerId,
                    ),
                  ),
                ),
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
              crossAxisAlignment: CrossAxisAlignment.start,
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