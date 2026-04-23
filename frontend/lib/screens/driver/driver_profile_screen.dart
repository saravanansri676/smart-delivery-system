import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../login_screen.dart';
import '../../services/logout_helper.dart';

class DriverProfileScreen extends StatefulWidget {
  final String driverId;
  const DriverProfileScreen(
      {super.key, required this.driverId});

  @override
  State<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState
    extends State<DriverProfileScreen> {
  Map<String, dynamic> driverData = {};
  bool isLoading = true;
  bool isSaving = false;
  bool isUpdatingStatus = false;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchDriver();
  }

  Future<void> fetchDriver() async {
    setState(() => isLoading = true);
    try {
      final profileRes = await http.get(Uri.parse(
          '$baseUrl/auth/driver/profile'
              '/${widget.driverId}'));

      final driverRes = await http
          .get(Uri.parse('$baseUrl/drivers/all'));

      if (driverRes.statusCode == 200) {
        final all =
        jsonDecode(driverRes.body) as List;
        final fullDriver = all.firstWhere(
              (d) => d['driverId'] == widget.driverId,
          orElse: () => <String, dynamic>{},
        );

        Map<String, dynamic> merged = {};
        if (fullDriver.isNotEmpty) {
          merged = Map<String, dynamic>.from(fullDriver);
        }
        if (profileRes.statusCode == 200) {
          final profileData = jsonDecode(profileRes.body)
          as Map<String, dynamic>;
          merged.addAll(profileData);
        }

        setState(() {
          driverData = merged;
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ── Manual status toggle ────────────────────────────────
  // AVAILABLE → OFFLINE (early leave)
  // OFFLINE → AVAILABLE (back on duty)
  Future<void> _toggleStatus() async {
    final currentStatus =
        driverData['status'] ?? 'OFFLINE';

    // ON_DELIVERY drivers cannot manually go offline
    if (currentStatus == 'ON_DELIVERY') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Cannot change status while on delivery. '
                  'Complete your deliveries first.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final isAvailable = currentStatus == 'AVAILABLE';
    final newStatus = isAvailable ? 'OFFLINE' : 'AVAILABLE';
    final actionText =
    isAvailable ? 'Go Offline' : 'Go Available';
    final messageText = isAvailable
        ? 'Are you sure you want to leave early?\n'
        'Your status will be set to Offline.'
        : 'Are you sure you want to go back on duty?\n'
        'Your status will be set to Available.';

    // Confirm dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(actionText),
        content: Text(messageText),
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
              backgroundColor: isAvailable
                  ? Colors.orange.shade700
                  : const Color(0xFF2E7D32),
              foregroundColor: Colors.white,
            ),
            child: Text(actionText),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => isUpdatingStatus = true);

    try {
      final response = await http.put(Uri.parse(
          '$baseUrl/drivers/status/${widget.driverId}'
              '?status=$newStatus'));

      if (response.statusCode == 200) {
        setState(() {
          driverData['status'] = newStatus;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isAvailable
                  ? 'You are now Offline. See you tomorrow!'
                  : 'You are now Available for deliveries!',
            ),
            backgroundColor: isAvailable
                ? Colors.orange.shade700
                : Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        _showError('Failed to update status. Try again.');
      }
    } catch (e) {
      _showError('Connection error.');
    }

    setState(() => isUpdatingStatus = false);
  }

  // ── Save profile ────────────────────────────────────────
  Future<bool> _saveProfile(
      Map<String, dynamic> updatedData) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$baseUrl/drivers/profile'
                '/${widget.driverId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );
      return response.statusCode == 200 &&
          response.body.contains('updated successfully');
    } catch (e) {
      return false;
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(
        text: driverData['name'] ?? '');
    final mobileController = TextEditingController(
        text: driverData['mobileNumber'] ?? '');
    final ageController = TextEditingController(
        text: driverData['age'] != null &&
            driverData['age'] != 0
            ? '${driverData['age']}'
            : '');
    String selectedSex =
    (driverData['sex'] != null &&
        driverData['sex'].toString().isNotEmpty)
        ? driverData['sex']
        : 'Male';

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20)),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.edit_rounded,
                        color: Color(0xFF1B5E20),
                        size: 20),
                    const SizedBox(width: 8),
                    const Text('Edit Profile',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1B5E20),
                        )),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Changes will be saved to your account',
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500)),
                const Divider(height: 24),

                _buildEditField(nameController,
                    'Full Name', Icons.person_rounded),
                const SizedBox(height: 12),
                _buildEditField(
                    mobileController,
                    'Mobile Number',
                    Icons.phone_rounded,
                    isNumber: true),
                const SizedBox(height: 12),

                // Age + Sex
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: ageController,
                        keyboardType:
                        TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter
                              .digitsOnly,
                          LengthLimitingTextInputFormatter(
                              3),
                        ],
                        decoration: InputDecoration(
                          labelText: 'Age',
                          prefixIcon: const Icon(
                              Icons.cake_rounded,
                              color: Color(0xFF1B5E20)),
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(
                                12),
                          ),
                          contentPadding:
                          const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text('Sex',
                              style: TextStyle(
                                  fontSize: 12,
                                  color:
                                  Colors.grey.shade600,
                                  fontWeight:
                                  FontWeight.w500)),
                          const SizedBox(height: 6),
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius:
                              BorderRadius.circular(
                                  12),
                              border: Border.all(
                                  color: Colors
                                      .grey.shade300),
                            ),
                            child:
                            DropdownButtonHideUnderline(
                              child:
                              DropdownButton<String>(
                                value: selectedSex,
                                isExpanded: true,
                                items: [
                                  'Male',
                                  'Female',
                                  'Other'
                                ]
                                    .map((s) =>
                                    DropdownMenuItem(
                                        value: s,
                                        child:
                                        Text(s)))
                                    .toList(),
                                onChanged: (val) =>
                                    setDialogState(() =>
                                    selectedSex =
                                    val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () =>
                            Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  10)),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                          final updated = {
                            'name': nameController
                                .text.trim(),
                            'mobileNumber':
                            mobileController
                                .text.trim(),
                            'age': int.tryParse(
                                ageController
                                    .text
                                    .trim()) ??
                                0,
                            'sex': selectedSex,
                          };
                          Navigator.pop(context);
                          setState(
                                  () => isSaving = true);
                          final success =
                          await _saveProfile(
                              updated);
                          if (success) {
                            await fetchDriver();
                            ScaffoldMessenger.of(
                                context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    ' Profile saved!'),
                                backgroundColor:
                                Colors.green,
                                behavior:
                                SnackBarBehavior
                                    .floating,
                              ),
                            );
                          } else {
                            _showError(
                                'Save failed. Try again.');
                          }
                          setState(
                                  () => isSaving = false);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                          const Color(0xFF1B5E20),
                          foregroundColor: Colors.white,
                          padding:
                          const EdgeInsets.symmetric(
                              vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(
                                  10)),
                        ),
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEditField(
      TextEditingController controller,
      String label,
      IconData icon, {
        bool isNumber = false,
      }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
        Icon(icon, color: const Color(0xFF1B5E20)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
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

  void _showLogoutDialog() {
    showLogoutDialog(context);
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AVAILABLE':
        return const Color(0xFF2E7D32);
      case 'ON_DELIVERY':
        return const Color(0xFFE65100);
      case 'OFFLINE':
        return Colors.grey.shade600;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'AVAILABLE':
        return Icons.check_circle_rounded;
      case 'ON_DELIVERY':
        return Icons.local_shipping_rounded;
      case 'OFFLINE':
        return Icons.cancel_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  String _getStatusButtonLabel(String status) {
    switch (status) {
      case 'AVAILABLE':
        return 'Tap to Go Offline';
      case 'OFFLINE':
        return 'Tap to Go Available';
      case 'ON_DELIVERY':
        return 'On Delivery — Cannot Change';
      default:
        return status;
    }
  }

  String _safeString(dynamic val,
      [String fallback = 'Not set']) {
    if (val == null) return fallback;
    final s = val.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _safeAge(dynamic val) {
    if (val == null) return 'Not set';
    final n =
    val is int ? val : int.tryParse('$val');
    if (n == null || n == 0) return 'Not set';
    return '$n';
  }

  void _showPackages(String status) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _DriverPackageListScreen(
          driverId: widget.driverId,
          status: status,
          baseUrl: baseUrl,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
          body: Center(
              child: CircularProgressIndicator()));
    }

    final status = driverData['status'] ?? 'OFFLINE';
    final statusColor = _getStatusColor(status);
    final canToggle = status != 'ON_DELIVERY';

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF1B5E20),
            leading: IconButton(
              icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF1B5E20),
                      Color(0xFF388E3C)
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor:
                      Colors.white.withOpacity(0.2),
                      child: Text(
                        (_safeString(
                            driverData['name'],
                            driverData['driverId'] ??
                                'DR'))
                            .substring(0, 2)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _safeString(
                          driverData['name'], 'Driver'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      driverData['driverId'] ?? '',
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

                // ── Status Button ──────────────────────
                // Tappable — driver can toggle AVAILABLE ↔ OFFLINE
                GestureDetector(
                  onTap: isUpdatingStatus
                      ? null
                      : _toggleStatus,
                  child: AnimatedContainer(
                    duration:
                    const Duration(milliseconds: 300),
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 20),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius:
                      BorderRadius.circular(14),
                      border: Border.all(
                          color:
                          statusColor.withOpacity(0.4),
                          width: 1.5),
                    ),
                    child: isUpdatingStatus
                        ? Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: statusColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text('Updating...',
                            style: TextStyle(
                                color: statusColor,
                                fontWeight:
                                FontWeight.w600)),
                      ],
                    )
                        : Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(
                            _getStatusIcon(status),
                            color: statusColor,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          status,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight:
                            FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                        if (canToggle) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding:
                            const EdgeInsets
                                .symmetric(
                                horizontal: 8,
                                vertical: 2),
                            decoration: BoxDecoration(
                              color: statusColor
                                  .withOpacity(0.15),
                              borderRadius:
                              BorderRadius
                                  .circular(20),
                            ),
                            child: Text(
                              _getStatusButtonLabel(
                                  status),
                              style: TextStyle(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight:
                                FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Helper text below status button
                if (canToggle)
                  Center(
                    child: Text(
                      status == 'AVAILABLE'
                          ? 'Tap the status button to leave early'
                          : 'Tap the status button to go back on duty',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Personal Details
                _buildSection(
                  title: 'Personal Details',
                  icon: Icons.person_rounded,
                  children: [
                    _buildRow(Icons.cake_rounded, 'Age',
                        _safeAge(driverData['age'])),
                    _buildRow(Icons.wc_rounded, 'Sex',
                        _safeString(driverData['sex'])),
                    _buildRow(Icons.phone_rounded,
                        'Mobile',
                        _safeString(
                            driverData['mobileNumber'])),
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
                        _safeString(
                            driverData['companyName'])),
                    _buildRow(
                        Icons.access_time_rounded,
                        'Work Hours',
                        '${driverData['workStartTime'] ?? '09:00'}'
                            ' - '
                            '${driverData['workEndTime'] ?? '16:00'}'),
                    _buildRow(Icons.circle, 'Status',
                        status),
                  ],
                ),
                const SizedBox(height: 16),

                // Performance
                _buildSection(
                  title: 'Performance Overview',
                  icon: Icons.bar_chart_rounded,
                  children: [
                    _buildClickableRow(
                      icon: Icons.inventory_rounded,
                      label: 'Packages Assigned',
                      value:
                      '${driverData['packagesAssigned'] ?? 0}',
                      color: const Color(0xFF0D47A1),
                      onTap: () =>
                          _showPackages('ASSIGNED'),
                    ),
                    _buildClickableRow(
                      icon: Icons.check_circle_rounded,
                      label: 'Packages Delivered',
                      value:
                      '${driverData['packagesDelivered'] ?? 0}',
                      color: const Color(0xFF2E7D32),
                      onTap: () =>
                          _showPackages('DELIVERED'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Rating
                _buildSection(
                  title: 'Rating',
                  icon: Icons.star_rounded,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          final rating =
                          ((driverData['averageRating'] ??
                              0.0) as num)
                              .toDouble();
                          return Icon(
                            index < rating.floor()
                                ? Icons.star_rounded
                                : index < rating
                                ? Icons
                                .star_half_rounded
                                : Icons
                                .star_outline_rounded,
                            color:
                            const Color(0xFFFFC107),
                            size: 28,
                          );
                        }),
                        const SizedBox(width: 8),
                        Text(
                          '${driverData['averageRating'] ?? 0.0}/5',
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
                    _buildRow(Icons.report_rounded,
                        'Penalties',
                        '${driverData['penaltyCount'] ?? 0}'),
                    _buildRow(Icons.list_alt_rounded,
                        'Reasons',
                        _safeString(
                            driverData['penaltyReasons'],
                            'None')),
                    _buildRow(Icons.speed_rounded,
                        'Driving Score',
                        '${driverData['drivingScore'] ?? 0}/100'),
                  ],
                ),
                const SizedBox(height: 24),

                // Actions
                _buildSection(
                  title: 'Actions',
                  icon: Icons.settings_rounded,
                  children: [
                    _buildActionButton(
                      icon: Icons.edit_rounded,
                      label: 'Edit Profile',
                      color: const Color(0xFF1B5E20),
                      onTap: _showEditDialog,
                    ),
                    const SizedBox(height: 12),
                    _buildActionButton(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      color: Colors.red,
                      onTap: _showLogoutDialog,
                    ),
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
                  color: const Color(0xFF1B5E20),
                  size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
                  )),
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
          Icon(icon,
              size: 18, color: Colors.grey.shade400),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                )),
          ),
          Expanded(
            child: Text(value,
                style: const TextStyle(
                  fontSize: 13,
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.w600,
                )),
          ),
        ],
      ),
    );
  }

  Widget _buildClickableRow({
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
              child: Text(label,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500,
                  )),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(value,
                  style: TextStyle(
                    fontSize: 13,
                    color: color,
                    fontWeight: FontWeight.w700,
                  )),
            ),
            const SizedBox(width: 4),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 12, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border:
          Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: color,
                  )),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14,
                color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}

// ── Package list ─────────────────────────────────────────
class _DriverPackageListScreen extends StatefulWidget {
  final String driverId;
  final String status;
  final String baseUrl;

  const _DriverPackageListScreen({
    required this.driverId,
    required this.status,
    required this.baseUrl,
  });

  @override
  State<_DriverPackageListScreen> createState() =>
      _DriverPackageListScreenState();
}

class _DriverPackageListScreenState
    extends State<_DriverPackageListScreen> {
  List packages = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    try {
      final response = await http.get(Uri.parse(
          '${widget.baseUrl}/packages/by-driver-status'
              '?driverId=${widget.driverId}'
              '&status=${widget.status}'));
      if (response.statusCode == 200) {
        setState(() {
          packages = jsonDecode(response.body) as List;
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
          icon:
          const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator())
          : packages.isEmpty
          ? const Center(
          child: Text('No packages found'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final pkg = packages[index];
          return Card(
            margin: const EdgeInsets.only(
                bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF1B5E20),
              ),
              title: Text(
                  pkg['packageName'] ?? ''),
              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(pkg['address'] ?? ''),
                  Text(
                      'Deadline: ${pkg['deadline'] ?? ''}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}