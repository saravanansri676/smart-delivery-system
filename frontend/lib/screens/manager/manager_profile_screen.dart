import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../login_screen.dart';
import '../../services/logout_helper.dart';

class ManagerProfileScreen extends StatefulWidget {
  final String managerId;
  final String managerName;
  final String managerEmail;
  final String companyName;

  const ManagerProfileScreen({
    super.key,
    required this.managerId,
    required this.managerName,
    required this.managerEmail,
    required this.companyName,
  });

  @override
  State<ManagerProfileScreen> createState() =>
      _ManagerProfileScreenState();
}

class _ManagerProfileScreenState
    extends State<ManagerProfileScreen> {
  Map<String, dynamic> managerData = {};
  Map<String, dynamic> statusData = {};
  bool isLoading = true;
  bool isSaving = false;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchData();
  }

  Future<void> fetchData() async {
    setState(() => isLoading = true);
    try {
      // Fetch profile, delivery status, and drivers
      final results = await Future.wait([
        http.get(Uri.parse(
            '$baseUrl/auth/manager/profile'
                '/${widget.managerId}')),
        http.get(Uri.parse(
            '$baseUrl/delivery/status')),
        http.get(Uri.parse('$baseUrl/drivers/all')),
      ]);

      final profileRes = results[0];
      final statusRes = results[1];
      final driversRes = results[2];

      if (profileRes.statusCode == 200) {
        final profile = jsonDecode(profileRes.body)
        as Map<String, dynamic>;

        final status = statusRes.statusCode == 200
            ? jsonDecode(statusRes.body)
        as Map<String, dynamic>
            : <String, dynamic>{};

        final drivers = driversRes.statusCode == 200
            ? jsonDecode(driversRes.body) as List
            : [];

        final activeDrivers = drivers
            .where((d) => d['status'] == 'ON_DELIVERY')
            .length;
        final inactiveDrivers = drivers
            .where((d) =>
        d['status'] == 'AVAILABLE' ||
            d['status'] == 'OFFLINE')
            .length;

        setState(() {
          managerData = profile;
          statusData = {
            ...status,
            'totalDrivers': drivers.length,
            'activeDrivers': activeDrivers,
            'inactiveDrivers': inactiveDrivers,
          };
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ── Save profile to backend ──────────────────────────────
  Future<bool> _saveProfile(
      Map<String, dynamic> updatedData) async {
    try {
      final response = await http.put(
        Uri.parse(
            '$baseUrl/auth/manager/profile'
                '/${widget.managerId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(updatedData),
      );
      return response.statusCode == 200 &&
          response.body
              .contains('updated successfully');
    } catch (e) {
      return false;
    }
  }

  void _showEditDialog() {
    // Pre-fill all fields with current data
    final nameController = TextEditingController(
        text: managerData['name'] ?? '');
    final emailController = TextEditingController(
        text: managerData['email'] ?? '');
    final phoneController = TextEditingController(
        text: managerData['mobileNumber'] ?? '');
    final companyController = TextEditingController(
        text: managerData['companyName'] ?? '');
    final locationController = TextEditingController(
        text: managerData['officeLocation'] ?? '');
    final ageController = TextEditingController(
        text: managerData['age'] != null &&
            managerData['age'] != 0
            ? '${managerData['age']}'
            : '');
    final joinedDateController = TextEditingController(
        text: managerData['joinedDate'] ?? '');

    // Sex dropdown — default to first option if not set
    String selectedSex =
    (managerData['sex'] != null &&
        managerData['sex'].toString().isNotEmpty)
        ? managerData['sex']
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
                // Header
                Row(
                  children: [
                    const Icon(Icons.edit_rounded,
                        color: Color(0xFF0D47A1),
                        size: 20),
                    const SizedBox(width: 8),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D47A1),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Changes will be saved to your account',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                  ),
                ),
                const Divider(height: 24),

                // ── Personal Info ──────────────────────
                _sectionLabel('Personal Information'),
                const SizedBox(height: 12),

                _buildEditField(nameController,
                    'Full Name', Icons.person_rounded),
                const SizedBox(height: 12),

                // Age + Sex in a row
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
                              color: Color(0xFF0D47A1)),
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
                              child: DropdownButton<String>(
                                value: selectedSex,
                                isExpanded: true,
                                items: ['Male',
                                  'Female',
                                  'Other']
                                    .map((s) =>
                                    DropdownMenuItem(
                                        value: s,
                                        child: Text(s)))
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
                const SizedBox(height: 12),

                _buildEditField(phoneController,
                    'Mobile Number', Icons.phone_rounded,
                    isNumber: true),
                const SizedBox(height: 20),

                // ── Company Info ───────────────────────
                _sectionLabel('Company Information'),
                const SizedBox(height: 12),

                _buildEditField(emailController, 'Email',
                    Icons.email_rounded),
                const SizedBox(height: 12),

                _buildEditField(companyController,
                    'Company Name',
                    Icons.business_rounded),
                const SizedBox(height: 12),

                _buildEditField(locationController,
                    'Office Location',
                    Icons.location_on_rounded),
                const SizedBox(height: 12),

                // Joined Date picker
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime.now(),
                      builder: (context, child) => Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme:
                          const ColorScheme.light(
                              primary:
                              Color(0xFF0D47A1)),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      final formatted =
                          '${picked.year}-'
                          '${picked.month.toString().padLeft(2, '0')}-'
                          '${picked.day.toString().padLeft(2, '0')}';
                      setDialogState(() =>
                      joinedDateController.text =
                          formatted);
                    }
                  },
                  child: AbsorbPointer(
                    child: TextFormField(
                      controller: joinedDateController,
                      decoration: InputDecoration(
                        labelText: 'Joined Date',
                        hintText: 'Tap to select',
                        prefixIcon: const Icon(
                            Icons.calendar_today_rounded,
                            color: Color(0xFF0D47A1)),
                        suffixIcon: const Icon(
                            Icons.arrow_drop_down_rounded,
                            color: Colors.grey),
                        border: OutlineInputBorder(
                          borderRadius:
                          BorderRadius.circular(12),
                        ),
                        contentPadding:
                        const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // ── Action buttons ─────────────────────
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
                            BorderRadius.circular(10),
                          ),
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
                          // Build update payload
                          final updated = {
                            'name':
                            nameController.text
                                .trim(),
                            'email':
                            emailController.text
                                .trim(),
                            'mobileNumber':
                            phoneController.text
                                .trim(),
                            'companyName':
                            companyController
                                .text.trim(),
                            'officeLocation':
                            locationController
                                .text.trim(),
                            'age': int.tryParse(
                                ageController
                                    .text
                                    .trim()) ??
                                0,
                            'sex': selectedSex,
                            'joinedDate':
                            joinedDateController
                                .text.trim(),
                          };

                          setState(
                                  () => isSaving = true);
                          Navigator.pop(context);

                          final success =
                          await _saveProfile(
                              updated);

                          if (success) {
                            // Refresh from backend
                            await fetchData();
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
                            ScaffoldMessenger.of(
                                context)
                                .showSnackBar(
                              const SnackBar(
                                content: Text(
                                    ' Save failed. Try again.'),
                                backgroundColor:
                                Colors.red,
                                behavior:
                                SnackBarBehavior
                                    .floating,
                              ),
                            );
                          }
                          setState(
                                  () => isSaving = false);
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
                            BorderRadius.circular(10),
                          ),
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

  Widget _sectionLabel(String label) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: const Color(0xFF0D47A1),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D47A1),
            letterSpacing: 0.5,
          ),
        ),
      ],
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
      keyboardType:
      isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
        Icon(icon, color: const Color(0xFF0D47A1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, vertical: 12),
      ),
    );
  }

  void _showLogoutDialog() {
    showLogoutDialog(context);
  }

  String _safeString(dynamic val,
      [String fallback = 'Not set']) {
    if (val == null) return fallback;
    final s = val.toString().trim();
    return s.isEmpty ? fallback : s;
  }

  String _safeAge(dynamic val) {
    if (val == null) return 'Not set';
    final n = val is int ? val : int.tryParse('$val');
    if (n == null || n == 0) return 'Not set';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: isLoading
          ? const Center(
          child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor:
            const Color(0xFF0D47A1),
            leading: IconButton(
              icon: const Icon(
                  Icons.arrow_back_ios_rounded,
                  color: Colors.white),
              onPressed: () =>
                  Navigator.pop(context),
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
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 40),
                    CircleAvatar(
                      radius: 45,
                      backgroundColor: Colors.white
                          .withOpacity(0.2),
                      child: const Icon(
                        Icons
                            .admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _safeString(
                          managerData['name'],
                          'Manager'),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      widget.managerId,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontFamily: 'monospace',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.green
                            .withOpacity(0.2),
                        borderRadius:
                        BorderRadius.circular(
                            20),
                        border: Border.all(
                            color: Colors.green
                                .withOpacity(0.5)),
                      ),
                      child: Text(
                        _safeString(
                            managerData[
                            'accountStatus'],
                            'ACTIVE'),
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
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

                // Personal Details
                _buildSection(
                  title: 'Personal Details',
                  icon: Icons.person_rounded,
                  children: [
                    _buildRow(
                        Icons.badge_rounded,
                        'Manager ID',
                        widget.managerId),
                    _buildRow(
                        Icons.cake_rounded,
                        'Age',
                        _safeAge(
                            managerData['age'])),
                    _buildRow(
                        Icons.wc_rounded,
                        'Sex',
                        _safeString(
                            managerData['sex'])),
                    _buildRow(
                        Icons.email_rounded,
                        'Email',
                        _safeString(
                            managerData['email'])),
                    _buildRow(
                        Icons.phone_rounded,
                        'Mobile',
                        _safeString(managerData[
                        'mobileNumber'])),
                  ],
                ),
                const SizedBox(height: 16),

                // Company Details
                _buildSection(
                  title: 'Company Details',
                  icon: Icons.business_rounded,
                  children: [
                    _buildRow(
                        Icons.business_rounded,
                        'Company',
                        _safeString(managerData[
                        'companyName'])),
                    _buildRow(
                        Icons.location_on_rounded,
                        'Location',
                        _safeString(managerData[
                        'officeLocation'])),
                    _buildRow(
                        Icons.calendar_today_rounded,
                        'Joined',
                        _safeString(
                            managerData[
                            'joinedDate'])),
                    _buildRow(
                        Icons.verified_rounded,
                        'Account',
                        _safeString(managerData[
                        'accountStatus'],
                            'ACTIVE')),
                  ],
                ),
                const SizedBox(height: 16),

                // Work Stats
                _buildSection(
                  title: 'Work Overview',
                  icon: Icons.work_rounded,
                  children: [
                    _buildRow(
                        Icons.inventory_rounded,
                        'Total Packages',
                        '${statusData['totalPackages'] ?? 0}'),
                    _buildRow(
                        Icons.people_rounded,
                        'Total Drivers',
                        '${statusData['totalDrivers'] ?? 0}'),
                    _buildRow(
                        Icons.drive_eta_rounded,
                        'Active Drivers',
                        '${statusData['activeDrivers'] ?? 0}'),
                    _buildRow(
                        Icons.person_off_rounded,
                        'Inactive Drivers',
                        '${statusData['inactiveDrivers'] ?? 0}'),
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
                      color: const Color(0xFF0D47A1),
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
                  color: const Color(0xFF0D47A1),
                  size: 18),
              const SizedBox(width: 8),
              Text(title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D47A1),
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