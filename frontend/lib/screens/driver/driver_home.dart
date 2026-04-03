import 'package:flutter/material.dart';
import 'register_driver_screen.dart';
import 'view_route_screen.dart';
import 'fuel_status_screen.dart';
import 'report_incident_screen.dart';
import 'map_route_screen.dart';
import 'weather_screen.dart';
import 'driver_profile_screen.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  String driverId = '';
  final _driverIdController = TextEditingController();

  @override
  Widget build(BuildContext context) {
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
            onPressed: () {
              if (driverId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Please enter Driver ID first'),
                    backgroundColor: Colors.red,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                return;
              }
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => DriverProfileScreen(
                      driverId: driverId),
                ),
              );
            },
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
                  colors: [Color(0xFF1B5E20), Color(0xFF388E3C)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.3),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.drive_eta_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driverId.isEmpty
                            ? 'Welcome, Driver'
                            : 'Driver $driverId',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Text(
                        'Smart Delivery System',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Driver ID input
            TextField(
              controller: _driverIdController,
              decoration: InputDecoration(
                labelText: 'Enter Your Driver ID',
                hintText: 'e.g. DRV001',
                prefixIcon: const Icon(
                    Icons.badge_rounded,
                    color: Color(0xFF0D47A1)),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF0D47A1)),
                  onPressed: () {
                    setState(() =>
                    driverId = _driverIdController.text);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                            'Driver ID set: ${_driverIdController.text}'),
                        backgroundColor:
                        const Color(0xFF0D47A1),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                          BorderRadius.circular(10),
                        ),
                      ),
                    );
                  },
                ),
              ),
              onChanged: (val) =>
                  setState(() => driverId = val),
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
                  icon: Icons.person_add_rounded,
                  title: 'Register',
                  subtitle: 'Join as driver',
                  color: const Color(0xFF0D47A1),
                  onTap: () => _navigate(
                      context, const RegisterDriverScreen()),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.route_rounded,
                  title: 'My Route',
                  subtitle: 'View delivery stops',
                  color: const Color(0xFF2E7D32),
                  onTap: () => _navigateWithId(
                    context,
                    ViewRouteScreen(driverId: driverId),
                  ),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.map_rounded,
                  title: 'Route Map',
                  subtitle: 'Visual navigation',
                  color: const Color(0xFF00838F),
                  onTap: () => _navigateWithId(
                    context,
                    MapRouteScreen(driverId: driverId),
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
                      latitude: 13.0827,
                      longitude: 80.2707,
                    ),
                  ),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.local_gas_station_rounded,
                  title: 'Fuel Status',
                  subtitle: 'Check & update fuel',
                  color: const Color(0xFFE65100),
                  onTap: () => _navigateWithId(
                    context,
                    FuelStatusScreen(driverId: driverId),
                  ),
                ),
                _buildMenuCard(
                  context,
                  icon: Icons.warning_rounded,
                  title: 'Report Issue',
                  subtitle: 'Vehicle incidents',
                  color: const Color(0xFFC62828),
                  onTap: () => _navigateWithId(
                    context,
                    ReportIncidentScreen(driverId: driverId),
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
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  void _navigateWithId(BuildContext context, Widget screen) {
    if (driverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter Driver ID first'),
          backgroundColor: Colors.red.shade700,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      return;
    }
    _navigate(context, screen);
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