import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../login_screen.dart';

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
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    managerData = {
      'managerId': widget.managerId,
      'name': widget.managerName,
      'email': widget.managerEmail,
      'companyName': widget.companyName,
      'age': 'N/A',
      'sex': 'N/A',
      'mobileNumber': 'N/A',
      'officeLocation': 'N/A',
      'joinedDate': 'N/A',
      'accountStatus': 'ACTIVE',
    };
    fetchData();
  }

  Future<void> fetchData() async {
    try {
      // Fetch manager profile from backend
      final profileResponse = await http.get(
        Uri.parse('$baseUrl/auth/manager/profile'
            '/${widget.managerId}'),
      );

      // Fetch delivery status
      final statusResponse = await http
          .get(Uri.parse('$baseUrl/delivery/status'));

      // Fetch drivers
      final driversResponse = await http
          .get(Uri.parse('$baseUrl/drivers/all'));

      if (profileResponse.statusCode == 200) {
        final profileJson =
        jsonDecode(profileResponse.body)
        as Map<String, dynamic>;

        final statusJson =
        statusResponse.statusCode == 200
            ? jsonDecode(statusResponse.body)
            : {};

        final drivers =
        driversResponse.statusCode == 200
            ? jsonDecode(driversResponse.body) as List
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
          // Merge backend data with local data
          managerData = {
            'managerId':
            profileJson['managerId'] ??
                widget.managerId,
            'name': profileJson['name'] ??
                widget.managerName,
            'email': profileJson['email'] ??
                widget.managerEmail,
            'companyName':
            profileJson['companyName'] ??
                widget.companyName,
            'accountStatus':
            profileJson['accountStatus'] ?? 'ACTIVE',
            'age': managerData['age'] ?? 'N/A',
            'sex': managerData['sex'] ?? 'N/A',
            'mobileNumber':
            managerData['mobileNumber'] ?? 'N/A',
            'officeLocation':
            managerData['officeLocation'] ?? 'N/A',
            'joinedDate':
            managerData['joinedDate'] ?? 'N/A',
          };
          statusData = {
            ...Map<String, dynamic>.from(statusJson),
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

  void _showEditDialog() {
    final nameController = TextEditingController(
        text: managerData['name']);
    final emailController = TextEditingController(
        text: managerData['email']);
    final phoneController = TextEditingController(
        text: managerData['mobileNumber']);
    final companyController = TextEditingController(
        text: managerData['companyName']);
    final locationController = TextEditingController(
        text: managerData['officeLocation']);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Edit Profile',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D47A1),
                ),
              ),
              const SizedBox(height: 20),
              _buildEditField(nameController, 'Name',
                  Icons.person_rounded),
              const SizedBox(height: 12),
              _buildEditField(emailController, 'Email',
                  Icons.email_rounded),
              const SizedBox(height: 12),
              _buildEditField(phoneController,
                  'Mobile Number', Icons.phone_rounded),
              const SizedBox(height: 12),
              _buildEditField(companyController,
                  'Company Name', Icons.business_rounded),
              const SizedBox(height: 12),
              _buildEditField(locationController,
                  'Office Location',
                  Icons.location_on_rounded),
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
                          BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          managerData['name'] =
                              nameController.text;
                          managerData['email'] =
                              emailController.text;
                          managerData['mobileNumber'] =
                              phoneController.text;
                          managerData['companyName'] =
                              companyController.text;
                          managerData['officeLocation'] =
                              locationController.text;
                        });
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Profile updated!'),
                            backgroundColor:
                            Colors.green,
                            behavior:
                            SnackBarBehavior.floating,
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
    );
  }

  Widget _buildEditField(TextEditingController controller,
      String label, IconData icon) {
    return TextField(
      controller: controller,
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
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text(
            'Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                    builder: (_) => const LoginScreen()),
                    (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: const Color(0xFF0D47A1),
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
                      backgroundColor:
                      Colors.white.withOpacity(0.2),
                      child: const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      managerData['name'] ?? 'Manager',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      managerData['managerId'] ?? '',
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
                        color:
                        Colors.green.withOpacity(0.2),
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.green
                                .withOpacity(0.5)),
                      ),
                      child: Text(
                        managerData['accountStatus'] ??
                            'ACTIVE',
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
                    _buildRow(Icons.badge_rounded,
                        'Manager ID',
                        managerData['managerId'] ?? ''),
                    _buildRow(Icons.cake_rounded,
                        'Age',
                        '${managerData['age'] ?? 'N/A'}'),
                    _buildRow(Icons.wc_rounded,
                        'Sex',
                        managerData['sex'] ?? 'N/A'),
                    _buildRow(Icons.email_rounded,
                        'Email',
                        managerData['email'] ?? 'N/A'),
                    _buildRow(Icons.phone_rounded,
                        'Mobile',
                        managerData['mobileNumber'] ??
                            'N/A'),
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
                        managerData['companyName'] ??
                            'N/A'),
                    _buildRow(
                        Icons.location_on_rounded,
                        'Location',
                        managerData['officeLocation'] ??
                            'N/A'),
                    _buildRow(
                        Icons.calendar_today_rounded,
                        'Joined',
                        managerData['joinedDate'] ??
                            'N/A'),
                    _buildRow(
                        Icons.verified_rounded,
                        'Account',
                        managerData['accountStatus'] ??
                            'ACTIVE'),
                  ],
                ),
                const SizedBox(height: 16),

                // Work Details
                _buildSection(
                  title: 'Work Details',
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
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
  }
}