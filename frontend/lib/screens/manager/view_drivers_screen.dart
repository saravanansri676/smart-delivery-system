import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewDriversScreen extends StatefulWidget {
  const ViewDriversScreen({super.key});

  @override
  State<ViewDriversScreen> createState() =>
      _ViewDriversScreenState();
}

class _ViewDriversScreenState extends State<ViewDriversScreen> {
  List drivers = [];
  bool isLoading = true;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchDrivers();
  }

  Future<void> fetchDrivers() async {
    try {
      final response =
      await http.get(Uri.parse('$baseUrl/drivers/all'));
      if (response.statusCode == 200) {
        setState(() {
          drivers = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Drivers'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchDrivers,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : drivers.isEmpty
          ? const Center(child: Text('No drivers found'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: drivers.length,
        itemBuilder: (context, index) {
          final driver = drivers[index];
          bool isAvailable =
              driver['status'] == 'AVAILABLE';
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: isAvailable
                    ? Colors.green
                    : Colors.orange,
                child: const Icon(Icons.drive_eta,
                    color: Colors.white),
              ),
              title: Text(
                  'Driver ${driver['driverId']}'),
              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                      'Vehicle: ${driver['vehicleNo']}'),
                  Text('Fuel: ${driver['fuelLevel']}'),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isAvailable
                      ? Colors.green
                      : Colors.orange,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  driver['status'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}