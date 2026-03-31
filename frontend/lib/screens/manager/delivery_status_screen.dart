import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DeliveryStatusScreen extends StatefulWidget {
  const DeliveryStatusScreen({super.key});

  @override
  State<DeliveryStatusScreen> createState() =>
      _DeliveryStatusScreenState();
}

class _DeliveryStatusScreenState
    extends State<DeliveryStatusScreen> {
  Map status = {};
  bool isLoading = true;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    try {
      final response =
      await http.get(Uri.parse('$baseUrl/delivery/status'));
      if (response.statusCode == 200) {
        setState(() {
          status = jsonDecode(response.body);
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
        title: const Text('Live Delivery Status'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchStatus,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildStatusCard(
              'Total Packages',
              '${status['totalPackages'] ?? 0}',
              Icons.inventory,
              const Color(0xFF1565C0),
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              'Packages In Store',
              '${status['packagesInStore'] ?? 0}',
              Icons.store,
              Colors.blue,
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              'Packages Assigned',
              '${status['packagesAssigned'] ?? 0}',
              Icons.assignment,
              Colors.orange,
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              'Packages Delivered',
              '${status['packagesDelivered'] ?? 0}',
              Icons.check_circle,
              Colors.green,
            ),
            const SizedBox(height: 16),
            _buildStatusCard(
              'Active Drivers',
              '${status['activeDrivers'] ?? 0}',
              Icons.drive_eta,
              Colors.purple,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(String title, String value,
      IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 30),
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 14, color: Colors.grey)),
              Text(value,
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: color)),
            ],
          ),
        ],
      ),
    );
  }
}