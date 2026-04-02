import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package_detail_screen.dart';

class ViewPackagesScreen extends StatefulWidget {
  const ViewPackagesScreen({super.key});

  @override
  State<ViewPackagesScreen> createState() => _ViewPackagesScreenState();
}

class _ViewPackagesScreenState extends State<ViewPackagesScreen> {
  List packages = [];
  bool isLoading = true;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/packages/all'),
      );

      if (response.statusCode == 200) {
        setState(() {
          packages = jsonDecode(response.body);
        });
      } else {
        throw Exception("Failed to load packages");
      }
    } catch (e) {
      debugPrint("Error fetching packages: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to load packages")),
      );
    } finally {
      setState(() => isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_STORE':
        return Colors.blue;
      case 'ASSIGNED':
        return Colors.orange;
      case 'MOVING':
        return Colors.purple;
      case 'DELIVERED':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Packages'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchPackages,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : packages.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
        onRefresh: fetchPackages,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: packages.length,
          itemBuilder: (context, index) {
            final pkg = packages[index];

            return GestureDetector(
              onTap: () => Navigator.push(
                context,
                PageRouteBuilder(
                  pageBuilder: (_, a, b) =>
                      PackageDetailScreen(package: pkg),
                  transitionsBuilder: (_, a, b, child) =>
                      SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(1, 0),
                          end: Offset.zero,
                        ).animate(
                          CurvedAnimation(
                            parent: a,
                            curve: Curves.easeOut,
                          ),
                        ),
                        child: child,
                      ),
                  transitionDuration:
                  const Duration(milliseconds: 300),
                ),
              ),
              child: Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      // Icon box
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _getStatusColor(
                              pkg['status'] ?? '')
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.inventory_2_rounded,
                          color: _getStatusColor(
                              pkg['status'] ?? ''),
                          size: 24,
                        ),
                      ),

                      const SizedBox(width: 14),

                      // Package details
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              pkg['packageName'] ?? '',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF1A1A2E),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pkg['address'] ?? '',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Deadline: ${pkg['deadline'] ?? ''}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: Color(0xFF0D47A1),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 8),

                      // Status section
                      Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                  pkg['status'] ?? ''),
                              borderRadius:
                              BorderRadius.circular(20),
                            ),
                            child: Text(
                              pkg['status'] ?? '',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 60,
            color: Colors.grey,
          ),
          SizedBox(height: 10),
          Text(
            'No packages found',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}