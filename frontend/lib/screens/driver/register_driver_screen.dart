import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class RegisterDriverScreen extends StatefulWidget {
  const RegisterDriverScreen({super.key});

  @override
  State<RegisterDriverScreen> createState() =>
      _RegisterDriverScreenState();
}

class _RegisterDriverScreenState
    extends State<RegisterDriverScreen> {
  final _driverIdController = TextEditingController();
  final _vehicleNoController = TextEditingController();
  final _capacityController = TextEditingController();
  String _fuelLevel = 'FULL';
  bool _isLoading = false;
  final String baseUrl = 'http://10.0.2.2:8080';

  Future<void> _registerDriver() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/drivers/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'driverId': _driverIdController.text,
          'vehicleNo': _vehicleNoController.text,
          'workStartTime': '09:00',
          'workEndTime': '16:00',
          'fuelLevel': _fuelLevel,
          'vehicleCapacity':
          double.parse(_capacityController.text),
          'currentLatitude': 13.0827,
          'currentLongitude': 80.2707,
        }),
      );
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Registered successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Driver'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: _driverIdController,
              decoration: InputDecoration(
                labelText: 'Driver ID',
                prefixIcon: const Icon(Icons.badge),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _vehicleNoController,
              decoration: InputDecoration(
                labelText: 'Vehicle Number',
                prefixIcon: const Icon(Icons.drive_eta),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _capacityController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Vehicle Capacity',
                prefixIcon: const Icon(Icons.inventory),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Fuel level selector
            const Text('Current Fuel Level',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Row(
              children: ['FULL', 'MID', 'LOW'].map((level) {
                Color color = level == 'FULL'
                    ? Colors.green
                    : level == 'MID'
                    ? Colors.orange
                    : Colors.red;
                return Expanded(
                  child: GestureDetector(
                    onTap: () =>
                        setState(() => _fuelLevel = level),
                    child: Container(
                      margin: const EdgeInsets.symmetric(
                          horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 12),
                      decoration: BoxDecoration(
                        color: _fuelLevel == level
                            ? color
                            : color.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        level,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: _fuelLevel == level
                              ? Colors.white
                              : color,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _registerDriver,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : const Text('Register',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}