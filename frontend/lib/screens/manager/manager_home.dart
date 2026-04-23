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
import '../../services/depot_service.dart';

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
  bool _isGeneratingPlan = false;

  // Live counts shown in the plan button area
  int _inStoreCount = 0;
  int _availableDriverCount = 0;

  @override
  void initState() {
    super.initState();
    _checkPendingRequests();
    _fetchLiveCounts();
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
          (_) {
        _checkPendingRequests();
        _fetchLiveCounts();
      },
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  // ── Fetch IN_STORE package count + AVAILABLE drivers ────
  Future<void> _fetchLiveCounts() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/delivery/status'));
      if (response.statusCode == 200) {
        final data =
        jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _inStoreCount =
          (data['packagesInStore'] ?? 0) as int;
          _availableDriverCount =
          (data['availableDrivers'] ?? 0) as int;
        });
      }
    } catch (e) {
      debugPrint('Count fetch error: $e');
    }
  }

  // ── Generate delivery plan ───────────────────────────────
  Future<void> _generatePlan() async {
    if (_inStoreCount == 0) {
      _showInfo('No packages in store to assign.');
      return;
    }
    if (_availableDriverCount == 0) {
      _showInfo('No available drivers to assign to.');
      return;
    }

    // Confirm before assigning
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Generate Delivery Plan'),
        content: Text(
          'This will assign $_inStoreCount package'
              '${_inStoreCount == 1 ? '' : 's'} to '
              '$_availableDriverCount available driver'
              '${_availableDriverCount == 1 ? '' : 's'}.\n\n'
              'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0D47A1),
              foregroundColor: Colors.white,
            ),
            child: const Text('Assign'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isGeneratingPlan = true);

    try {
      // Fetch depot coords for this manager
      final coords = await DepotService.getDepotCoords(
          widget.managerId);
      final lat = coords[0];
      final lon = coords[1];

      final response = await http.post(
        Uri.parse(
            '$baseUrl/delivery/plan'
                '?startLat=$lat&startLon=$lon'),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body)
        as Map<String, dynamic>;

        // Refresh counts after assignment
        await _fetchLiveCounts();

        // Show result dialog
        _showPlanResult(result);
      } else {
        _showError('Failed to generate plan. Try again.');
      }
    } catch (e) {
      _showError('Connection error: $e');
    }

    setState(() => _isGeneratingPlan = false);
  }

  // ── Show plan result ─────────────────────────────────────
  void _showPlanResult(Map<String, dynamic> result) {
    final driverPlans =
        result['driverPlans'] as List? ?? [];
    final totalPackages = result['totalPackages'] ?? 0;
    final driversAssigned =
        result['driversAssigned'] ?? 0;

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
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
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Plan Generated!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$totalPackages packages assigned to '
                    '$driversAssigned driver'
                    '${driversAssigned == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Per-driver summary
              if (driverPlans.isNotEmpty)
                ...driverPlans.map((plan) {
                  final driverId =
                      plan['driverId'] ?? '';
                  final count =
                      plan['packagesCount'] ?? 0;
                  final timeReport =
                      plan['timeWindowReport'] ?? '';
                  final fuelReport =
                      plan['fuelReport'] ?? '';

                  return Container(
                    margin: const EdgeInsets.only(
                        bottom: 12),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius:
                      BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF0D47A1)
                              .withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                                Icons.drive_eta_rounded,
                                color: Color(0xFF0D47A1),
                                size: 16),
                            const SizedBox(width: 6),
                            Text(
                              'Driver $driverId',
                              style: const TextStyle(
                                fontWeight:
                                FontWeight.w700,
                                fontSize: 14,
                                color: Color(0xFF0D47A1),
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding:
                              const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green
                                    .withOpacity(0.1),
                                borderRadius:
                                BorderRadius.circular(
                                    20),
                              ),
                              child: Text(
                                '$count packages',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.green,
                                  fontWeight:
                                  FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (timeReport.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            timeReport,
                            style: TextStyle(
                              fontSize: 11,
                              color:
                              Colors.grey.shade600,
                            ),
                          ),
                        ],
                        if (fuelReport.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            fuelReport,
                            style: TextStyle(
                              fontSize: 11,
                              color: fuelReport
                                  .contains('WARNING')
                                  ? Colors.red.shade700
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),

              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Polling for driver requests ──────────────────────────
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
                child: const Icon(
                    Icons.person_add_rounded,
                    color: Color(0xFF0D47A1),
                    size: 40),
              ),
              const SizedBox(height: 16),
              const Text('New Driver Request!',
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E))),
              const SizedBox(height: 8),
              Text(
                '${_pendingRequests.length} driver '
                    'registration request'
                    '${_pendingRequests.length == 1 ? '' : 's'} '
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
                        padding:
                        const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                10)),
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
                        padding:
                        const EdgeInsets.symmetric(
                            vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius.circular(
                                10)),
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

  void _showInfo(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.orange.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)),
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
          // Notification bell
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
            icon: const Icon(
                Icons.account_circle_rounded,
                color: Colors.white,
                size: 28),
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
                        Text(
                            'Welcome, ${widget.managerName}!',
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

            // ── Generate Delivery Plan banner ────────────
            // Shows only when there are packages to assign
            GestureDetector(
              onTap: _isGeneratingPlan
                  ? null
                  : _generatePlan,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: _inStoreCount > 0
                        ? [
                      const Color(0xFF2E7D32),
                      const Color(0xFF388E3C)
                    ]
                        : [
                      Colors.grey.shade400,
                      Colors.grey.shade500
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: (_inStoreCount > 0
                          ? const Color(0xFF2E7D32)
                          : Colors.grey)
                          .withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: _isGeneratingPlan
                    ? const Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child:
                      CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Generating Plan...',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                )
                    : Row(
                  children: [
                    Container(
                      padding:
                      const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.2),
                        borderRadius:
                        BorderRadius.circular(
                            10),
                      ),
                      child: const Icon(
                        Icons.route_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          const Text(
                            'Generate Delivery Plan',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                          Text(
                            _inStoreCount > 0
                                ? '$_inStoreCount package'
                                '${_inStoreCount == 1 ? '' : 's'}'
                                ' waiting · '
                                '$_availableDriverCount driver'
                                '${_availableDriverCount == 1 ? '' : 's'}'
                                ' available'
                                : 'No packages in store',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.white70,
                      size: 16,
                    ),
                  ],
                ),
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
                      const Icon(
                          Icons.person_add_rounded,
                          color: Colors.orange,
                          size: 28),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                          CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${_pendingRequests.length}'
                                  ' Pending Driver Request'
                                  '${_pendingRequests.length == 1 ? '' : 's'}',
                              style: const TextStyle(
                                  fontWeight:
                                  FontWeight.w700,
                                  fontSize: 15,
                                  color:
                                  Color(0xFF1A1A2E)),
                            ),
                            const Text('Tap to review',
                                style: TextStyle(
                                    fontSize: 12,
                                    color:
                                    Colors.orange)),
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
                    onTap: () => _navigate(context,
                        const ViewDriversScreen())),
                _buildMenuCard(context,
                    icon: Icons.dashboard_rounded,
                    title: 'Live Status',
                    subtitle: 'Delivery dashboard',
                    color: const Color(0xFF6A1B9A),
                    onTap: () => _navigate(context,
                        const DeliveryStatusScreen())),
                _buildMenuCard(context,
                    icon: Icons.warehouse_rounded,
                    title: 'Depot Settings',
                    subtitle: 'Set warehouse location',
                    color: const Color(0xFF00838F),
                    onTap: () => _navigate(
                      context,
                      DepotSettingsScreen(
                          managerId:
                          widget.managerId),
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
              crossAxisAlignment:
              CrossAxisAlignment.start,
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