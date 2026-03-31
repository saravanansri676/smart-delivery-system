import 'package:flutter/material.dart';
import 'register_driver_screen.dart';
import 'view_route_screen.dart';
import 'fuel_status_screen.dart';
import 'report_incident_screen.dart';
import 'map_route_screen.dart';
import 'weather_screen.dart';

class DriverHome extends StatefulWidget {
  const DriverHome({super.key});

  @override
  State<DriverHome> createState() => _DriverHomeState();
}

class _DriverHomeState extends State<DriverHome> {
  String driverId = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Enter Your Driver ID',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onChanged: (val) =>
                  setState(() => driverId = val),
            ),
            const SizedBox(height: 24),
            const Text(
              'Quick Actions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1565C0),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildMenuCard(
                    context,
                    icon: Icons.person_add,
                    title: 'Register',
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                        const RegisterDriverScreen(),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.route,
                    title: 'My Route',
                    color: const Color(0xFF2E7D32),
                    onTap: () => _navigateWithId(
                      context,
                      ViewRouteScreen(driverId: driverId),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.map,
                    title: 'Route Map',
                    color: const Color(0xFF00838F),
                    onTap: () => _navigateWithId(
                      context,
                      MapRouteScreen(driverId: driverId),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.cloud,
                    title: 'Weather',
                    color: const Color(0xFF1565C0),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WeatherScreen(
                          latitude: 13.0827,
                          longitude: 80.2707,
                        ),
                      ),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.local_gas_station,
                    title: 'Fuel Status',
                    color: const Color(0xFFE65100),
                    onTap: () => _navigateWithId(
                      context,
                      FuelStatusScreen(driverId: driverId),
                    ),
                  ),
                  _buildMenuCard(
                    context,
                    icon: Icons.warning,
                    title: 'Report Incident',
                    color: const Color(0xFFC62828),
                    onTap: () => _navigateWithId(
                      context,
                      ReportIncidentScreen(
                          driverId: driverId),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateWithId(BuildContext context, Widget screen) {
    if (driverId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter Driver ID first')),
      );
      return;
    }
    Navigator.push(
        context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildMenuCard(BuildContext context,
      {required IconData icon,
        required String title,
        required Color color,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 40, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}