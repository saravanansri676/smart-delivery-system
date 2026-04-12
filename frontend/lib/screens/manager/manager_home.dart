import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'add_package_screen.dart';
import 'view_packages_screen.dart';
import 'view_drivers_screen.dart';
import 'delivery_status_screen.dart';
import 'manager_profile_screen.dart';
import 'driver_request_screen.dart';
import 'depot_settings_screen.dart';

class ManagerHome extends StatefulWidget {
  final String managerId;
  final String managerName;
  final String managerEmail;
  final String companyName;

  const ManagerHome({
    super.key,
    required this.managerId,
    required this.managerName,
    required this.managerEmail,
    required this.companyName,
  });

  @override
  State<ManagerHome> createState() => _ManagerHomeState();
}

class _ManagerHomeState extends State<ManagerHome> {
  final String baseUrl = 'http://10.0.2.2:8080';
  List<dynamic> _pendingRequests = [];
  Timer? _pollingTimer;
  bool _popupShown = false;

  @override
  void initState() {
    super.initState();
    _checkPendingRequests();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) => _checkPendingRequests(),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> _checkPendingRequests() async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/driver-requests/pending'
              '/${widget.managerId}'));
      if (response.statusCode == 200) {
        final List<dynamic> requests =
        jsonDecode(response.body);
        if (requests.isNotEmpty && !_popupShown) {
          setState(() => _pendingRequests = requests);
          _showRequestPopup();
        } else {
          setState(() => _pendingRequests = requests);
        }
      }
    } catch (e) {
      debugPrint('Polling error: $e');
    }
  }

  void _showRequestPopup() {
    _popupShown = true;
    showDialog(
      context: context,
      barrierDismissible: true,
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
                  color: const Color(0xFF0D47A1)
                      .withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.person_add_rounded,
                    color: Color(0xFF0D47A1), size: 40),
              ),
              const SizedBox(height: 16),
              const Text('New Driver Request!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Text(
                '${_pendingRequests.length} driver registration '
                    '${_pendingRequests.length == 1 ? 'request' : 'requests'} '
                    'waiting for your approval.',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.4),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _popupShown = false;
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10)),
                      ),
                      child: const Text('Later'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _popupShown = false;
                        _navigate(
                          context,
                          DriverRequestScreen(
                            managerId: widget.managerId,
                            pendingRequests:
                            _pendingRequests,
                            onRequestProcessed:
                            _checkPendingRequests,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                        const Color(0xFF0D47A1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(10)),
                      ),
                      child: const Text('See Details'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    ).then((_) => _popupShown = false);
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      PageRouteBuilder(
        pageBuilder: (_, a, b) => screen,
        transitionsBuilder: (_, a, b, child) =>
            SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1, 0),
                end: Offset.zero,
              ).animate(CurvedAnimation(
                  parent: a, curve: Curves.easeOut)),
              child: child,
            ),
        transitionDuration:
        const Duration(milliseconds: 300),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Manager Dashboard'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Stack(
            children: [
              IconButton(
                icon: const Icon(
                    Icons.notifications_rounded,
                    color: Colors.white,
                    size: 28),
                onPressed: () {
                  if (_pendingRequests.isNotEmpty) {
                    _navigate(
                      context,
                      DriverRequestScreen(
                        managerId: widget.managerId,
                        pendingRequests: _pendingRequests,
                        onRequestProcessed:
                        _checkPendingRequests,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context)
                        .showSnackBar(const SnackBar(
                      content: Text(
                          'No pending driver requests'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  }
                },
              ),
              if (_pendingRequests.isNotEmpty)
                Positioned(
                  right: 8,
                  top: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle),
                    child: Text(
                      '${_pendingRequests.length}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_rounded,
                color: Colors.white, size: 28),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ManagerProfileScreen(
                  managerId: widget.managerId,
                  managerName: widget.managerName,
                  managerEmail: widget.managerEmail,
                  companyName: widget.companyName,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card
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
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Text('Welcome, ${widget.managerName}!',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight:
                                FontWeight.w700)),
                        Text(widget.companyName,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13)),
                        Text(widget.managerId,
                            style: const TextStyle(
                                color: Colors.white60,
                                fontSize: 12,
                                fontFamily: 'monospace')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Pending requests banner
            if (_pendingRequests.isNotEmpty)
              GestureDetector(
                onTap: () => _navigate(
                  context,
                  DriverRequestScreen(
                    managerId: widget.managerId,
                    pendingRequests: _pendingRequests,
                    onRequestProcessed:
                    _checkPendingRequests,
                  ),
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  margin:
                  const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius:
                    BorderRadius.circular(14),
                    border: Border.all(
                        color: Colors.orange.shade300),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.person_add_rounded,
                          color: Colors.orange, size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_pendingRequests.length} Pending Driver '
                                  '${_pendingRequests.length == 1 ? 'Request' : 'Requests'}',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: Color(0xFF1A1A2E)),
                            ),
                            const Text('Tap to review',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.orange)),
                          ],
                        ),
                      ),
                      const Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: Colors.orange),
                    ],
                  ),
                ),
              ),

            const Text('QUICK ACTIONS',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D47A1),
                    letterSpacing: 1.5)),
            const SizedBox(height: 16),

            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.1,
              children: [
                _buildMenuCard(context,
                    icon: Icons.add_box_rounded,
                    title: 'Add Package',
                    subtitle: 'Register new package',
                    color: const Color(0xFF0D47A1),
                    onTap: () => _navigate(
                        context, const AddPackageScreen())),
                _buildMenuCard(context,
                    icon: Icons.inventory_2_rounded,
                    title: 'View Packages',
                    subtitle: 'Track all packages',
                    color: const Color(0xFF2E7D32),
                    onTap: () => _navigate(context,
                        const ViewPackagesScreen())),
                _buildMenuCard(context,
                    icon: Icons.people_rounded,
                    title: 'View Drivers',
                    subtitle: 'Monitor drivers',
                    color: const Color(0xFFE65100),
                    onTap: () => _navigate(
                        context, const ViewDriversScreen())),
                _buildMenuCard(context,
                    icon: Icons.dashboard_rounded,
                    title: 'Live Status',
                    subtitle: 'Delivery dashboard',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => _navigate(context,
                        const DeliveryStatusScreen())),
                // ✅ New card — Depot Settings
                _buildMenuCard(context,
                    icon: Icons.warehouse_rounded,
                    title: 'Depot Settings',
                    subtitle: 'Set warehouse location',
                    color: const Color(0xFF00838F),
                    onTap: () => _navigate(
                      context,
                      DepotSettingsScreen(
                          managerId: widget.managerId),
                    )),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuCard(BuildContext context,
      {required IconData icon,
        required String title,
        required String subtitle,
        required Color color,
        required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 16,
                offset: const Offset(0, 4))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E))),
                const SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}