import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package_detail_screen.dart';

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
      final response = await http
          .get(Uri.parse('$baseUrl/delivery/status'));
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

  void _openPackageList(
      BuildContext context, String filterStatus, String title) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => _FilteredPackagesScreen(
          filterStatus: filterStatus,
          title: title,
          baseUrl: baseUrl,
        ),
        transitionsBuilder: (_, a, b, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(
                  CurvedAnimation(parent: a, curve: Curves.easeOut)),
              child: child,
            ),
        transitionDuration: const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Live Delivery Status'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: fetchStatus,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Summary header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF0D47A1),
                    Color(0xFF1976D2)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0D47A1)
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
                      Icons.inventory_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Packages',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        '${status['totalPackages'] ?? 0}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'TAP TO VIEW DETAILS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0D47A1),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // Clickable status cards
            _buildStatusCard(
              context,
              title: 'Packages In Store',
              value: '${status['packagesInStore'] ?? 0}',
              icon: Icons.store_rounded,
              color: const Color(0xFF1565C0),
              filterStatus: 'IN_STORE',
              description: 'Waiting for assignment',
              onTap: () => _openPackageList(
                context,
                'IN_STORE',
                'Packages In Store',
              ),
            ),
            const SizedBox(height: 16),

            _buildStatusCard(
              context,
              title: 'Packages Assigned',
              value:
              '${status['packagesAssigned'] ?? 0}',
              icon: Icons.assignment_rounded,
              color: const Color(0xFFE65100),
              filterStatus: 'ASSIGNED',
              description: 'Assigned to drivers',
              onTap: () => _openPackageList(
                context,
                'ASSIGNED',
                'Assigned Packages',
              ),
            ),
            const SizedBox(height: 16),

            _buildStatusCard(
              context,
              title: 'Packages Delivered',
              value:
              '${status['packagesDelivered'] ?? 0}',
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF2E7D32),
              filterStatus: 'DELIVERED',
              description: 'Successfully delivered',
              onTap: () => _openPackageList(
                context,
                'DELIVERED',
                'Delivered Packages',
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(
      BuildContext context, {
        required String title,
        required String value,
        required IconData icon,
        required Color color,
        required String filterStatus,
        required String description,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: Colors.grey.shade400,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Filtered packages screen
class _FilteredPackagesScreen extends StatefulWidget {
  final String filterStatus;
  final String title;
  final String baseUrl;

  const _FilteredPackagesScreen({
    required this.filterStatus,
    required this.title,
    required this.baseUrl,
  });

  @override
  State<_FilteredPackagesScreen> createState() =>
      _FilteredPackagesScreenState();
}

class _FilteredPackagesScreenState
    extends State<_FilteredPackagesScreen> {
  List packages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    try {
      final response = await http
          .get(Uri.parse('${widget.baseUrl}/packages/all'));
      if (response.statusCode == 200) {
        final all = jsonDecode(response.body) as List;
        setState(() {
          packages = all
              .where((p) => p['status'] == widget.filterStatus)
              .toList();
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_STORE': return const Color(0xFF1565C0);
      case 'ASSIGNED': return const Color(0xFFE65100);
      case 'DELIVERED': return const Color(0xFF2E7D32);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getStatusColor(widget.filterStatus);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text(widget.title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: fetchPackages,
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : packages.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment:
          MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              'No ${widget.filterStatus.toLowerCase().replaceAll('_', ' ')} packages',
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 16,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final pkg = packages[index];
          return GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    PackageDetailScreen(package: pkg),
              ),
            ),
            child: Container(
              margin:
              const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.grey.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.inventory_2_rounded,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          pkg['packageName'] ?? '',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight:
                            FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pkg['address'] ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                            Colors.grey.shade500,
                          ),
                          maxLines: 1,
                          overflow:
                          TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Deadline: ${pkg['deadline'] ?? ''}',
                          style: TextStyle(
                            fontSize: 12,
                            color: color,
                            fontWeight:
                            FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 14,
                    color: Colors.grey,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}