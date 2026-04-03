import 'package:flutter/material.dart';
import '../manager/view_packages_screen.dart';
import 'package_detail_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DriverProfileScreen extends StatelessWidget {
  final Map driver;
  const DriverProfileScreen({super.key, required this.driver});

  @override
  Widget build(BuildContext context) {
    final status = driver['status'] ?? 'OFFLINE';
    final statusColor = _getStatusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        slivers: [
          // Profile header
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: const Color(0xFF0D47A1),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF0D47A1),
                      Color(0xFF1976D2)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    // Avatar
                    CircleAvatar(
                      radius: 40,
                      backgroundColor:
                      Colors.white.withOpacity(0.2),
                      child: Text(
                        driver['driverId']
                            ?.substring(0, 2)
                            .toUpperCase() ??
                            'DR',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      driver['name'] ??
                          driver['driverId'] ?? 'Driver',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      driver['driverId'] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Status card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(_getStatusIcon(status),
                          color: statusColor),
                      const SizedBox(width: 8),
                      Text(
                        'Status: $status',
                        style: TextStyle(
                          color: statusColor,
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Personal Details
                _buildSection(
                  title: 'Personal Details',
                  icon: Icons.person_rounded,
                  children: [
                    _buildRow(Icons.cake_rounded, 'Age',
                        '${driver['age'] ?? 'N/A'}'),
                    _buildRow(Icons.wc_rounded, 'Sex',
                        driver['sex'] ?? 'N/A'),
                    _buildRow(Icons.phone_rounded, 'Mobile',
                        driver['mobileNumber'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 16),

                // Work Details
                _buildSection(
                  title: 'Work Details',
                  icon: Icons.work_rounded,
                  children: [
                    _buildRow(Icons.business_rounded,
                        'Company',
                        driver['companyName'] ?? 'N/A'),
                    _buildRow(Icons.access_time_rounded,
                        'Work Hours',
                        '${driver['workStartTime'] ?? '09:00'} - ${driver['workEndTime'] ?? '16:00'}'),
                  ],
                ),
                const SizedBox(height: 16),

                // Performance
                _buildSection(
                  title: 'Performance Overview',
                  icon: Icons.bar_chart_rounded,
                  children: [
                    _buildClickableRow(
                      context,
                      icon: Icons.inventory_rounded,
                      label: 'Packages Assigned',
                      value:
                      '${driver['packagesAssigned'] ?? 0}',
                      color: const Color(0xFF0D47A1),
                      onTap: () => _showPackages(
                          context, 'ASSIGNED'),
                    ),
                    _buildClickableRow(
                      context,
                      icon: Icons.check_circle_rounded,
                      label: 'Packages Delivered',
                      value:
                      '${driver['packagesDelivered'] ?? 0}',
                      color: const Color(0xFF2E7D32),
                      onTap: () => _showPackages(
                          context, 'DELIVERED'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Ratings
                _buildSection(
                  title: 'Rating',
                  icon: Icons.star_rounded,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          final rating =
                          (driver['averageRating'] ?? 0.0)
                          as double;
                          return Icon(
                            index < rating.floor()
                                ? Icons.star_rounded
                                : index < rating
                                ? Icons.star_half_rounded
                                : Icons.star_outline_rounded,
                            color: const Color(0xFFFFC107),
                            size: 28,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${driver['averageRating'] ?? 0.0}/5',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Penalties
                _buildSection(
                  title: 'Penalties & Behavior',
                  icon: Icons.warning_rounded,
                  children: [
                    _buildRow(
                        Icons.report_rounded,
                        'Penalty Count',
                        '${driver['penaltyCount'] ?? 0}'),
                    _buildRow(
                        Icons.list_alt_rounded,
                        'Reasons',
                        driver['penaltyReasons'] ??
                            'None'),
                    _buildRow(
                        Icons.speed_rounded,
                        'Driving Score',
                        '${driver['drivingScore'] ?? 0}/100'),
                  ],
                ),
                const SizedBox(height: 16),

                // Vehicle Details
                _buildSection(
                  title: 'Vehicle Details',
                  icon: Icons.directions_car_rounded,
                  children: [
                    _buildRow(
                        Icons.confirmation_number_rounded,
                        'Vehicle No',
                        driver['vehicleNo'] ?? 'N/A'),
                    _buildRow(
                        Icons.directions_car_rounded,
                        'Vehicle Type',
                        driver['vehicleType'] ?? 'N/A'),
                    _buildRow(
                        Icons.scale_rounded,
                        'Capacity',
                        '${driver['vehicleCapacity'] ?? 0} kg'),
                    _buildRow(
                        Icons.local_gas_station_rounded,
                        'Fuel Level',
                        driver['fuelLevel'] ?? 'N/A'),
                  ],
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  void _showPackages(BuildContext context, String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _PackageListScreen(
          driverId: driver['driverId'],
          status: status,
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AVAILABLE': return const Color(0xFF2E7D32);
      case 'ON_DELIVERY': return const Color(0xFFE65100);
      case 'OFFLINE': return Colors.grey;
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'AVAILABLE': return Icons.check_circle_rounded;
      case 'ON_DELIVERY': return Icons.local_shipping_rounded;
      case 'OFFLINE': return Icons.cancel_rounded;
      default: return Icons.help_rounded;
    }
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon,
                  color: const Color(0xFF0D47A1), size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D47A1),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildRow(
      IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableRow(
      BuildContext context, {
        required IconData icon,
        required String label,
        required String value,
        required Color color,
        required VoidCallback onTap,
      }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}

// Package list screen for driver
class _PackageListScreen extends StatefulWidget {
  final String driverId;
  final String status;
  const _PackageListScreen(
      {required this.driverId, required this.status});

  @override
  State<_PackageListScreen> createState() =>
      _PackageListScreenState();
}

class _PackageListScreenState
    extends State<_PackageListScreen> {
  List packages = [];
  bool isLoading = true;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/packages/all'));
      if (response.statusCode == 200) {
        final all = jsonDecode(response.body) as List;
        setState(() {
          packages = all.where((p) =>
          p['assignedDriverId'] == widget.driverId &&
              p['status'] == widget.status).toList();
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
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: Text('${widget.status} Packages'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : packages.isEmpty
          ? const Center(
          child: Text('No packages found'))
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
                    PackageDetailScreen(
                        package: pkg),
              ),
            ),
            child: Card(
              margin: const EdgeInsets.only(
                  bottom: 12),
              shape: RoundedRectangleBorder(
                borderRadius:
                BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: const Icon(
                  Icons.inventory_2_rounded,
                  color: Color(0xFF0D47A1),
                ),
                title: Text(
                    pkg['packageName'] ?? ''),
                subtitle: Text(
                    pkg['address'] ?? ''),
                trailing: const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}