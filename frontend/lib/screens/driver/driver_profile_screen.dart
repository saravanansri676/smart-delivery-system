import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../login_screen.dart';

class DriverProfileScreen extends StatefulWidget {
  final String driverId;
  const DriverProfileScreen({super.key, required this.driverId});

  @override
  State<DriverProfileScreen> createState() =>
      _DriverProfileScreenState();
}

class _DriverProfileScreenState
    extends State<DriverProfileScreen> {
  Map<String, dynamic> driverData = {};
  bool isLoading = true;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchDriver();
  }

  Future<void> fetchDriver() async {
    try {
      final response = await http
          .get(Uri.parse('$baseUrl/drivers/all'));
      if (response.statusCode == 200) {
        final all = jsonDecode(response.body) as List;
        final driver = all.firstWhere(
              (d) => d['driverId'] == widget.driverId,
          orElse: () => {},
        );
        setState(() {
          driverData = Map<String, dynamic>.from(driver);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _updateDriver() async {
    try {
      // Update fuel level
      await http.put(Uri.parse(
          '$baseUrl/fuel/update/${widget.driverId}'
              '?fuelLevel=${driverData['fuelLevel']}'));
      // Update status
      await http.put(Uri.parse(
          '$baseUrl/drivers/status/${widget.driverId}'
              '?status=${driverData['status']}'));
    } catch (e) {
      print('Update error: $e');
    }
  }

  void _showEditDialog() {
    final nameController = TextEditingController(
        text: driverData['name'] ?? '');
    final mobileController = TextEditingController(
        text: driverData['mobileNumber'] ?? '');
    final companyController = TextEditingController(
        text: driverData['companyName'] ?? '');
    final vehicleNoController = TextEditingController(
        text: driverData['vehicleNo'] ?? '');
    String selectedVehicleType =
        driverData['vehicleType'] ?? 'BIKE';
    String selectedFuel =
        driverData['fuelLevel'] ?? 'FULL';
    String selectedSex = driverData['sex'] ?? 'Male';

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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Edit Profile',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1B5E20),
                  ),
                ),
                const SizedBox(height: 20),
                _buildEditField(nameController,
                    'Full Name', Icons.person_rounded),
                const SizedBox(height: 12),
                _buildEditField(mobileController,
                    'Mobile Number', Icons.phone_rounded,
                    isNumber: true),
                const SizedBox(height: 12),
                _buildEditField(companyController,
                    'Company Name',
                    Icons.business_rounded),
                const SizedBox(height: 12),
                _buildEditField(vehicleNoController,
                    'Vehicle Number',
                    Icons.confirmation_number_rounded),
                const SizedBox(height: 12),
                // Sex dropdown
                _buildDropdown(
                  label: 'Sex',
                  value: selectedSex,
                  items: ['Male', 'Female', 'Other'],
                  onChanged: (val) =>
                      setDialogState(() =>
                      selectedSex = val!),
                ),
                const SizedBox(height: 12),
                // Vehicle type dropdown
                _buildDropdown(
                  label: 'Vehicle Type',
                  value: selectedVehicleType,
                  items: ['BIKE', 'VAN', 'TRUCK'],
                  onChanged: (val) =>
                      setDialogState(() =>
                      selectedVehicleType = val!),
                ),
                const SizedBox(height: 12),
                // Fuel level
                const Text('Fuel Level',
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 8),
                Row(
                  children: ['FULL', 'MID', 'LOW']
                      .map((level) {
                    Color color = level == 'FULL'
                        ? Colors.green
                        : level == 'MID'
                        ? Colors.orange
                        : Colors.red;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setDialogState(
                                () => selectedFuel = level),
                        child: Container(
                          margin:
                          const EdgeInsets.symmetric(
                              horizontal: 4),
                          padding:
                          const EdgeInsets.symmetric(
                              vertical: 10),
                          decoration: BoxDecoration(
                            color: selectedFuel == level
                                ? color
                                : color.withOpacity(0.15),
                            borderRadius:
                            BorderRadius.circular(8),
                          ),
                          child: Text(
                            level,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: selectedFuel == level
                                  ? Colors.white
                                  : color,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
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
                            BorderRadius.circular(10),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          setState(() {
                            driverData['name'] =
                                nameController.text;
                            driverData['mobileNumber'] =
                                mobileController.text;
                            driverData['companyName'] =
                                companyController.text;
                            driverData['vehicleNo'] =
                                vehicleNoController.text;
                            driverData['sex'] =
                                selectedSex;
                            driverData['vehicleType'] =
                                selectedVehicleType;
                            driverData['fuelLevel'] =
                                selectedFuel;
                          });
                          await _updateDriver();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context)
                              .showSnackBar(
                            const SnackBar(
                              content:
                              Text('Profile updated!'),
                              backgroundColor:
                              Colors.green,
                              behavior:
                              SnackBarBehavior.floating,
                            ),
                          );
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

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Container(
          padding:
          const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade50,
            borderRadius: BorderRadius.circular(12),
            border:
            Border.all(color: Colors.grey.shade300),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              items: items
                  .map((s) => DropdownMenuItem(
                  value: s, child: Text(s)))
                  .toList(),
              onChanged: onChanged,
            ),
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
                    builder: (_) =>
                    const LoginScreen()),
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

  Color _getStatusColor(String status) {
    switch (status) {
      case 'AVAILABLE': return const Color(0xFF2E7D32);
      case 'ON_DELIVERY': return const Color(0xFFE65100);
      case 'OFFLINE': return Colors.grey;
      default: return Colors.grey;
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
                  color: const Color(0xFF1B5E20),
                  size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1B5E20),
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
          border: Border.all(
              color: color.withOpacity(0.2)),
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
                size: 14,
                color: color.withOpacity(0.5)),
          ],
        ),
      ),
    );
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
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final status = driverData['status'] ?? 'OFFLINE';
    final statusColor = _getStatusColor(status);

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
                        (driverData['name'] ??
                            driverData['driverId'] ??
                            'DR')
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
                      driverData['name'] ??
                          driverData['driverId'] ??
                          'Driver',
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
                // Status
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius:
                    BorderRadius.circular(12),
                    border: Border.all(
                        color:
                        statusColor.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment:
                    MainAxisAlignment.center,
                    children: [
                      Icon(Icons.circle,
                          color: statusColor, size: 12),
                      const SizedBox(width: 8),
                      Text(
                        status,
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
                        '${driverData['age'] ?? 'N/A'}'),
                    _buildRow(Icons.wc_rounded, 'Sex',
                        driverData['sex'] ?? 'N/A'),
                    _buildRow(Icons.phone_rounded,
                        'Mobile',
                        driverData['mobileNumber'] ??
                            'N/A'),
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
                        driverData['companyName'] ?? 'N/A'),
                    _buildRow(
                        Icons.access_time_rounded,
                        'Work Hours',
                        '${driverData['workStartTime'] ?? '09:00'} - ${driverData['workEndTime'] ?? '16:00'}'),
                    _buildRow(Icons.circle,
                        'Status', status),
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

                // Ratings
                _buildSection(
                  title: 'Rating',
                  icon: Icons.star_rounded,
                  children: [
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          final rating =
                          (driverData['averageRating'] ??
                              0.0)
                          as double;
                          return Icon(
                            index < rating.floor()
                                ? Icons.star_rounded
                                : index < rating
                                ? Icons.star_half_rounded
                                : Icons
                                .star_outline_rounded,
                            color: const Color(0xFFFFC107),
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
                        driverData['penaltyReasons'] ??
                            'None'),
                    _buildRow(Icons.speed_rounded,
                        'Driving Score',
                        '${driverData['drivingScore'] ?? 0}/100'),
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
                        driverData['vehicleNo'] ?? 'N/A'),
                    _buildRow(
                        Icons.directions_car_rounded,
                        'Vehicle Type',
                        driverData['vehicleType'] ?? 'N/A'),
                    _buildRow(Icons.scale_rounded,
                        'Capacity',
                        '${driverData['vehicleCapacity'] ?? 0} kg'),
                    _buildRow(
                        Icons.local_gas_station_rounded,
                        'Fuel Level',
                        driverData['fuelLevel'] ?? 'N/A'),
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
}

// Package list for driver view
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
      final response = await http
          .get(Uri.parse('${widget.baseUrl}/packages/all'));
      if (response.statusCode == 200) {
        final all = jsonDecode(response.body) as List;
        setState(() {
          packages = all
              .where((p) =>
          p['assignedDriverId'] ==
              widget.driverId &&
              p['status'] == widget.status)
              .toList();
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
          return Card(
            margin:
            const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius:
              BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(
                Icons.inventory_2_rounded,
                color: Color(0xFF1B5E20),
              ),
              title:
              Text(pkg['packageName'] ?? ''),
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