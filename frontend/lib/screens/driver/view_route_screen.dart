import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewRouteScreen extends StatefulWidget {
  final String driverId;
  const ViewRouteScreen({super.key, required this.driverId});

  @override
  State<ViewRouteScreen> createState() => _ViewRouteScreenState();
}

class _ViewRouteScreenState extends State<ViewRouteScreen> {
  List route = [];
  bool isLoading = true;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchRoute();
  }

  Future<void> fetchRoute() async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/route/optimize/${widget.driverId}'
              '?startLat=13.0827&startLon=80.2707'));
      if (response.statusCode == 200) {
        setState(() {
          route = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> markDelivered(String packageId) async {
    final response = await http.put(Uri.parse(
        '$baseUrl/reroute/delivered/$packageId'
            '?driverId=${widget.driverId}'
            '&currentLat=13.0827&currentLon=80.2707'));
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response.body)),
      );
      fetchRoute();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Route'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchRoute,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : route.isEmpty
          ? const Center(
          child: Text('No packages assigned'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: route.length,
        itemBuilder: (context, index) {
          final pkg = route[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                const Color(0xFF1565C0),
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: Colors.white)),
              ),
              title: Text(pkg['packageName'] ?? ''),
              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(pkg['address'] ?? ''),
                  Text(
                      'Deadline: ${pkg['deadline']}'),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () =>
                    markDelivered(pkg['packageId']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Done'),
              ),
            ),
          );
        },
      ),
    );
  }
}