import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/depot_service.dart';

class ViewRouteScreen extends StatefulWidget {
  final String driverId;
  final String managerId;

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
    try {
      final response = await http.put(Uri.parse(
          '$baseUrl/reroute/delivered/$packageId'
              '?driverId=${widget.driverId}'
              '&currentLat=$_startLat'
              '&currentLon=$_startLon'));

      if (response.statusCode == 200) {
        final result = response.body;

        if (result == 'ALL_DELIVERED') {
          // All packages done — show celebration dialog
          _showAllDeliveredDialog();
        } else if (result.startsWith('NEXT:')) {
          // Parse next stop info
          final parts =
          result.substring(5).split('|');
          final address =
          parts.isNotEmpty ? parts[0] : '';
          final name =
          parts.length > 1 ? parts[1] : '';
          final deadline =
          parts.length > 2 ? parts[2] : '';

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  const Text('✅ Package Delivered!',
                      style: TextStyle(
                          fontWeight: FontWeight.w700)),
                  Text(
                      'Next: $name — $address'
                          ' (Deadline: $deadline)',
                      style: const TextStyle(
                          fontSize: 12)),
                ],
              ),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
              shape: RoundedRectangleBorder(
                  borderRadius:
                  BorderRadius.circular(10)),
            ),
          );
          // Refresh route list
          fetchRoute();
        } else {
          // Package not found or other error
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result),
              behavior: SnackBarBehavior.floating,
            ),
          );
          fetchRoute();
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection error. Try again.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // ── All packages delivered celebration dialog ────────────
  void _showAllDeliveredDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Celebration emoji
              const Text('🎉',
                  style: TextStyle(fontSize: 64)),
              const SizedBox(height: 16),
              const Text(
                'All Delivered!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius:
                  BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.green.shade200),
                ),
                child: Column(
                  children: [
                    const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.green,
                        size: 40),
                    const SizedBox(height: 8),
                    const Text(
                      'Great job! All packages have '
                          'been successfully delivered.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Status update confirmation
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E7D32)
                            .withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                              Icons.circle,
                              color: Color(0xFF2E7D32),
                              size: 10),
                          SizedBox(width: 6),
                          Text(
                            'Your status is now AVAILABLE',
                            style: TextStyle(
                              fontSize: 12,
                              color: Color(0xFF2E7D32),
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    fetchRoute(); // refresh — will show empty
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF2E7D32),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Done — Great Job! 🚀',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(
                Icons.check_circle_outline_rounded,
                size: 72,
                color: Colors.green.shade300),
            const SizedBox(height: 16),
            const Text(
              'No packages assigned',
              style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey),
            ),
          ],
        ),
      )
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
                        color: Colors.white,
                        fontWeight:
                        FontWeight.bold)),
              ),
              title: Text(
                pkg['packageName'] ?? '',
                style: const TextStyle(
                    fontWeight:
                    FontWeight.w600),
              ),
              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(pkg['address'] ?? '',
                      maxLines: 2,
                      overflow: TextOverflow
                          .ellipsis),
                  Text(
                    'Deadline: ${pkg['deadline']}',
                    style: const TextStyle(
                      color: Color(0xFF1565C0),
                      fontWeight:
                      FontWeight.w500,
                    ),
                  ),
                ],
              ),
              trailing: ElevatedButton(
                onPressed: () => markDelivered(
                    pkg['packageId']),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets
                      .symmetric(
                      horizontal: 12,
                      vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(
                        8),
                  ),
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