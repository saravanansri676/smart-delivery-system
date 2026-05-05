import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'decline_reason_screen.dart';

class PackagesScreen extends StatefulWidget {
  final String driverId;

  const PackagesScreen({
    super.key,
    required this.driverId,
  });

  @override
  State<PackagesScreen> createState() =>
      _PackagesScreenState();
}

class _PackagesScreenState
    extends State<PackagesScreen> {
  List<dynamic> pendingPackages = [];
  List<dynamic> assignedPackages = [];
  List<dynamic> deliveredPackages = [];
  bool isLoading = true;
  bool isAccepting = false;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    setState(() => isLoading = true);
    try {
      // Fetch all three statuses in parallel
      final results = await Future.wait([
        http.get(Uri.parse(
            '$baseUrl/packages/by-driver-status'
                '?driverId=${widget.driverId}'
                '&status=PENDING_ACCEPTANCE')),
        http.get(Uri.parse(
            '$baseUrl/packages/by-driver-status'
                '?driverId=${widget.driverId}'
                '&status=ASSIGNED')),
        http.get(Uri.parse(
            '$baseUrl/packages/by-driver-status'
                '?driverId=${widget.driverId}'
                '&status=DELIVERED')),
      ]);

      setState(() {
        pendingPackages = results[0].statusCode == 200
            ? jsonDecode(results[0].body) as List
            : [];
        assignedPackages = results[1].statusCode == 200
            ? jsonDecode(results[1].body) as List
            : [];
        deliveredPackages = results[2].statusCode == 200
            ? jsonDecode(results[2].body) as List
            : [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ── Accept all pending packages ──────────────────────────
  Future<void> _acceptPackages() async {
    setState(() => isAccepting = true);
    try {
      final response = await http.put(Uri.parse(
          '$baseUrl/packages/accept/${widget.driverId}'));

      if (response.statusCode == 200 &&
          response.body.startsWith('ACCEPTED')) {
        // Show success popup
        _showAcceptedDialog();
        // Refresh packages
        await fetchPackages();
      } else {
        _showError('Failed to accept. Try again.');
      }
    } catch (e) {
      _showError('Connection error.');
    }
    setState(() => isAccepting = false);
  }

  // ── Show accepted popup ──────────────────────────────────
  void _showAcceptedDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: Colors.green,
                  size: 52,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Packages Accepted!',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Packages accepted successfully.\n'
                    'Visit My Route to start delivering.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context),
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
                    'Got it!',
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

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ── Check if deadline is urgent (within 2 hours) ─────────
  bool _isUrgent(String? deadline) {
    if (deadline == null || deadline.isEmpty)
      return false;
    try {
      final parts = deadline.split(':');
      final deadlineMinutes =
          int.parse(parts[0]) * 60 +
              int.parse(parts[1]);
      final now = DateTime.now();
      final nowMinutes =
          now.hour * 60 + now.minute;
      return (deadlineMinutes - nowMinutes) <= 120 &&
          (deadlineMinutes - nowMinutes) > 0;
    } catch (_) {
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Packages'),
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
          ? const Center(
          child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: fetchPackages,
        child: pendingPackages.isNotEmpty
            ? _buildPhase1()
            : _buildPhase2(),
      ),
    );
  }

  // ── Phase 1: Pending acceptance ──────────────────────────
  Widget _buildPhase1() {
    return Column(
      children: [
        // Header banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: const Color(0xFF0D47A1).withOpacity(0.08),
          child: Row(
            children: [
              const Icon(Icons.new_releases_rounded,
                  color: Color(0xFF0D47A1), size: 20),
              const SizedBox(width: 8),
              Text(
                'NEW ASSIGNMENTS — '
                    '${pendingPackages.length} package'
                    '${pendingPackages.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D47A1),
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),

        // Package list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(
                16, 16, 16, 100),
            itemCount: pendingPackages.length,
            itemBuilder: (context, index) {
              final pkg = pendingPackages[index];
              final urgent =
              _isUrgent(pkg['deadline']);

              return Container(
                margin:
                const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius:
                  BorderRadius.circular(14),
                  border: Border.all(
                    color: urgent
                        ? Colors.orange.shade300
                        : Colors.grey.shade200,
                    width: urgent ? 1.5 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                      Colors.grey.withOpacity(0.07),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    // Index circle
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: urgent
                            ? Colors.orange
                            : const Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Package info
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                pkg['packageId'] ?? '',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight:
                                  FontWeight.w700,
                                  color:
                                  Color(0xFF1A1A2E),
                                  fontFamily: 'monospace',
                                ),
                              ),
                              if (urgent) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding:
                                  const EdgeInsets
                                      .symmetric(
                                      horizontal: 6,
                                      vertical: 2),
                                  decoration:
                                  BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius:
                                    BorderRadius
                                        .circular(6),
                                  ),
                                  child: const Text(
                                    'URGENT',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9,
                                      fontWeight:
                                      FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pkg['address'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            pkg['deadline'] != null &&
                                pkg['deadline']
                                    .toString()
                                    .isNotEmpty
                                ? 'Deadline: ${pkg['deadline']}'
                                : 'Pending',
                            style: TextStyle(
                              fontSize: 12,
                              color: urgent
                                  ? Colors.orange.shade700
                                  : Colors.grey.shade500,
                              fontWeight: urgent
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),

        // Accept / Decline buttons
        Container(
          padding: const EdgeInsets.fromLTRB(
              16, 12, 16, 24),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Decline button
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: isAccepting
                      ? null
                      : () async {
                    final result =
                    await Navigator.push<bool>(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            DeclineReasonScreen(
                              driverId: widget.driverId,
                            ),
                      ),
                    );
                    if (result == true) {
                      fetchPackages();
                    }
                  },
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.red),
                  label: const Text('Decline',
                      style: TextStyle(
                          color: Colors.red,
                          fontSize: 16,
                          fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    side: const BorderSide(
                        color: Colors.red, width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Accept button
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                  isAccepting ? null : _acceptPackages,
                  icon: isAccepting
                      ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.check_rounded),
                  label: Text(
                    isAccepting ? 'Accepting...' : 'Accept',
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600),
                  ),
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
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Phase 2: Delivered / Undelivered ─────────────────────
  Widget _buildPhase2() {
    final total =
        assignedPackages.length + deliveredPackages.length;

    if (total == 0) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No packages assigned yet',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Packages will appear here once\n'
                  'the manager assigns them.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Progress bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFF1B5E20),
                  Color(0xFF388E3C)
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment:
                  MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Delivery Progress',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${deliveredPackages.length}/$total',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: total > 0
                        ? deliveredPackages.length / total
                        : 0,
                    backgroundColor:
                    Colors.white.withOpacity(0.3),
                    valueColor:
                    const AlwaysStoppedAnimation<Color>(
                        Colors.white),
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '${assignedPackages.length} remaining',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Undelivered section
          if (assignedPackages.isNotEmpty) ...[
            _sectionHeader(
              'Pending Delivery',
              Icons.local_shipping_rounded,
              const Color(0xFF0D47A1),
              assignedPackages.length,
            ),
            const SizedBox(height: 10),
            ...assignedPackages.map((pkg) =>
                _packageCard(pkg, false)),
            const SizedBox(height: 20),
          ],

          // Delivered section
          if (deliveredPackages.isNotEmpty) ...[
            _sectionHeader(
              'Delivered',
              Icons.check_circle_rounded,
              const Color(0xFF2E7D32),
              deliveredPackages.length,
            ),
            const SizedBox(height: 10),
            ...deliveredPackages.map((pkg) =>
                _packageCard(pkg, true)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon,
      Color color, int count) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 10, vertical: 3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _packageCard(dynamic pkg, bool delivered) {
    final color = delivered
        ? const Color(0xFF2E7D32)
        : const Color(0xFF0D47A1);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              delivered
                  ? Icons.check_rounded
                  : Icons.inventory_2_rounded,
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Text(
                  pkg['packageName'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  pkg['address'] ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              delivered ? 'Done' : 'Pending',
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}