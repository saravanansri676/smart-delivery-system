import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/depot_service.dart';

class ViewRouteScreen extends StatefulWidget {
  final String driverId;
  final String managerId; // needed to fetch depot coords

  const ViewRouteScreen({
    super.key,
    required this.driverId,
    required this.managerId,
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

  Future<void> fetchRoute() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/route/optimize/${widget.driverId}'
              '?startLat=$_startLat&startLon=$_startLon'));
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
            '&currentLat=$_startLat&currentLon=$_startLon'));
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchRoute,
          )
        ],
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator())
          : route.isEmpty
          ? const Center(
          child: Text('No packages assigned'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: route.length,
        itemBuilder: (context, index) {
          final pkg = route[index];
          return Card(
            margin: const EdgeInsets.only(
                bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor:
                const Color(0xFF1565C0),
                child: Text('${index + 1}',
                    style: const TextStyle(
                        color: Colors.white)),
              ),
              title: Text(
                  pkg['packageName'] ?? ''),
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
                onPressed: () => markDelivered(
                    pkg['packageId']),
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