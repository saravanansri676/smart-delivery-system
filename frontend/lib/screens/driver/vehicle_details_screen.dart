import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'route_type_screen.dart';

class VehicleDetailsScreen extends StatefulWidget {
  final String driverId;
  final String managerId;

  const VehicleDetailsScreen({
    super.key,
    required this.driverId,
    required this.managerId,
  });

  @override
  State<VehicleDetailsScreen> createState() =>
      _VehicleDetailsScreenState();
}

class _VehicleDetailsScreenState
    extends State<VehicleDetailsScreen> {
  final _vehicleNoController = TextEditingController();
  final _capacityController = TextEditingController();
  String _selectedVehicleType = 'BIKE';
  String _selectedFuel = 'FULL';
  bool _isSubmitting = false;
  final String baseUrl = 'http://10.0.2.2:8080';

  final List<Map<String, dynamic>> _vehicleTypes = [
    {
      'value': 'BIKE',
      'label': 'Bike',
      'icon': Icons.two_wheeler_rounded,
      'color': const Color(0xFF1565C0),
    },
    {
      'value': 'VAN',
      'label': 'Van',
      'icon': Icons.airport_shuttle_rounded,
      'color': const Color(0xFF2E7D32),
    },
    {
      'value': 'TRUCK',
      'label': 'Truck',
      'icon': Icons.local_shipping_rounded,
      'color': const Color(0xFFE65100),
    },
  ];

  Future<void> _submit() async {
    if (_vehicleNoController.text.trim().isEmpty) {
      _showError('Please enter vehicle number');
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final response = await http.put(
        Uri.parse(
            '$baseUrl/drivers/vehicle'
                '/${widget.driverId}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'vehicleType': _selectedVehicleType,
          'vehicleNo':
          _vehicleNoController.text.trim(),
          'vehicleCapacity': double.tryParse(
              _capacityController.text.trim()) ??
              0.0,
          'fuelLevel': _selectedFuel,
        }),
      );

      if (response.statusCode == 200 &&
          response.body
              .contains('updated successfully')) {
        // Navigate to route type selection
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => RouteTypeScreen(
              driverId: widget.driverId,
              managerId: widget.managerId,
            ),
          ),
        );
      } else {
        _showError('Failed to save. Try again.');
      }
    } catch (e) {
      _showError('Connection error.');
    }

    setState(() => _isSubmitting = false);
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

  @override
  void dispose() {
    _vehicleNoController.dispose();
    _capacityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Vehicle Details'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF0D47A1)
                    .withOpacity(0.07),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: const Color(0xFF0D47A1)
                        .withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(
                      Icons.directions_car_rounded,
                      color: Color(0xFF0D47A1),
                      size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Please enter your vehicle details '
                          'before starting the route.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Vehicle Type
            const Text(
              'Vehicle Type',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: _vehicleTypes.map((type) {
                final isSelected =
                    _selectedVehicleType ==
                        type['value'];
                final color =
                type['color'] as Color;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() =>
                    _selectedVehicleType =
                    type['value']),
                    child: AnimatedContainer(
                      duration: const Duration(
                          milliseconds: 200),
                      margin: const EdgeInsets
                          .symmetric(horizontal: 4),
                      padding: const EdgeInsets.symmetric(
                          vertical: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color
                            : Colors.white,
                        borderRadius:
                        BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : Colors.grey.shade300,
                          width: isSelected ? 2 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                          BoxShadow(
                            color: color
                                .withOpacity(0.3),
                            blurRadius: 8,
                            offset:
                            const Offset(0, 3),
                          )
                        ]
                            : [],
                      ),
                      child: Column(
                        children: [
                          Icon(
                            type['icon'] as IconData,
                            color: isSelected
                                ? Colors.white
                                : color,
                            size: 28,
                          ),
                          const SizedBox(height: 6),
                          Text(
                            type['label'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white
                                  : color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Registration Number
            const Text(
              'Registration Number',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _vehicleNoController,
              textCapitalization:
              TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'e.g. TN 37 AB 1234',
                prefixIcon: const Icon(
                    Icons.confirmation_number_rounded,
                    color: Color(0xFF0D47A1)),
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),

            // Capacity
            const Text(
              'Load Capacity (kg)',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _capacityController,
              keyboardType:
              const TextInputType.numberWithOptions(
                  decimal: true),
              decoration: InputDecoration(
                hintText: 'e.g. 50',
                prefixIcon: const Icon(
                    Icons.scale_rounded,
                    color: Color(0xFF0D47A1)),
                suffixText: 'kg',
                border: OutlineInputBorder(
                  borderRadius:
                  BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Fuel Level
            const Text(
              'Fuel Level',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _fuelOption('FULL', 'High',
                    Colors.green, Icons.battery_full_rounded),
                const SizedBox(width: 10),
                _fuelOption('MID', 'Medium',
                    Colors.orange,
                    Icons.battery_4_bar_rounded),
                const SizedBox(width: 10),
                _fuelOption('LOW', 'Low', Colors.red,
                    Icons.battery_1_bar_rounded),
              ],
            ),
            const SizedBox(height: 32),

            // Submit button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed:
                _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                    Icons.arrow_forward_rounded),
                label: Text(
                  _isSubmitting
                      ? 'Saving...'
                      : 'Continue to Route',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                  const Color(0xFF0D47A1),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _fuelOption(String value, String label,
      Color color, IconData icon) {
    final isSelected = _selectedFuel == value;
    return Expanded(
      child: GestureDetector(
        onTap: () =>
            setState(() => _selectedFuel = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(
              vertical: 14),
          decoration: BoxDecoration(
            color:
            isSelected ? color : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color
                  : Colors.grey.shade300,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isSelected
                ? [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 3),
              )
            ]
                : [],
          ),
          child: Column(
            children: [
              Icon(icon,
                  color: isSelected
                      ? Colors.white
                      : color,
                  size: 24),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? Colors.white
                      : color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}