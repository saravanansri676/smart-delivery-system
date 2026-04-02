import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class PackageDetailScreen extends StatelessWidget {
  final Map package;
  const PackageDetailScreen({super.key, required this.package});

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_STORE': return const Color(0xFF1565C0);
      case 'ASSIGNED': return const Color(0xFFE65100);
      case 'MOVING': return const Color(0xFF6A1B9A);
      case 'DELIVERED': return const Color(0xFF2E7D32);
      default: return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'IN_STORE': return Icons.store_rounded;
      case 'ASSIGNED': return Icons.assignment_rounded;
      case 'MOVING': return Icons.local_shipping_rounded;
      case 'DELIVERED': return Icons.check_circle_rounded;
      default: return Icons.help_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = package['status'] ?? 'IN_STORE';
    final statusColor = _getStatusColor(status);
    final qrData = jsonEncode(package);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Package Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Status banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    statusColor,
                    statusColor.withOpacity(0.7)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: statusColor.withOpacity(0.3),
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
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getStatusIcon(status),
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text(
                          package['packageName'] ?? '',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          package['packageId'] ?? '',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Package info
            _buildSection(
              title: 'Package Information',
              icon: Icons.inventory_2_rounded,
              children: [
                _buildDetailRow(
                    Icons.qr_code_rounded,
                    'Package ID',
                    package['packageId'] ?? ''),
                _buildDetailRow(
                    Icons.scale_rounded,
                    'Weight',
                    '${package['weightKg'] ?? 0} kg'),
                _buildDetailRow(
                    Icons.straighten_rounded,
                    'Size',
                    package['size'] ?? ''),
                _buildDetailRow(
                    Icons.schedule_rounded,
                    'Deadline',
                    package['deadlineDate'] ??
                        package['deadline'] ?? ''),
              ],
            ),
            const SizedBox(height: 16),

            // Receiver info
            _buildSection(
              title: 'Receiver Information',
              icon: Icons.person_rounded,
              children: [
                _buildDetailRow(
                    Icons.person_rounded,
                    'Name',
                    package['receiverName'] ?? 'N/A'),
                _buildDetailRow(
                    Icons.phone_rounded,
                    'Phone',
                    package['receiverPhone'] ?? 'N/A'),
                _buildDetailRow(
                    Icons.location_on_rounded,
                    'Address',
                    package['address'] ?? ''),
                _buildDetailRow(
                    Icons.map_rounded,
                    'Coordinates',
                    '${package['latitude']?.toStringAsFixed(4) ?? 0}'
                        ', ${package['longitude']?.toStringAsFixed(4) ?? 0}'),
              ],
            ),
            const SizedBox(height: 16),

            // Delivery info
            if (package['assignedDriverId'] != null &&
                package['assignedDriverId'].toString().isNotEmpty)
              _buildSection(
                title: 'Delivery Information',
                icon: Icons.local_shipping_rounded,
                children: [
                  _buildDetailRow(
                      Icons.drive_eta_rounded,
                      'Assigned Driver',
                      package['assignedDriverId'] ?? ''),
                  _buildDetailRow(
                      Icons.flag_rounded,
                      'Priority',
                      '${package['priority'] ?? 0}'),
                ],
              ),
            const SizedBox(height: 16),

            // QR Code section
            _buildSection(
              title: 'Package QR Code',
              icon: Icons.qr_code_2_rounded,
              children: [
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        QrImageView(
                          data: qrData,
                          version: QrVersions.auto,
                          size: 160,
                          backgroundColor: Colors.white,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          package['packageId'] ?? '',
                          style: const TextStyle(
                            fontSize: 11,
                            fontFamily: 'monospace',
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
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
                  letterSpacing: 0.5,
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

  Widget _buildDetailRow(
      IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
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
}