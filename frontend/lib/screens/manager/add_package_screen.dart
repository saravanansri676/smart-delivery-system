import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddPackageScreen extends StatefulWidget {
  const AddPackageScreen({super.key});

  @override
  State<AddPackageScreen> createState() => _AddPackageScreenState();
}

class _AddPackageScreenState extends State<AddPackageScreen> {
  final _packageIdController = TextEditingController();
  final _packageNameController = TextEditingController();
  final _addressController = TextEditingController();
  final _latController = TextEditingController();
  final _lonController = TextEditingController();
  final _deadlineController = TextEditingController();
  String _selectedSize = 'SMALL';
  bool _isLoading = false;

  final String baseUrl = 'http://10.0.2.2:8080';

  Future<void> _addPackage() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/packages/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'packageId': _packageIdController.text,
          'packageName': _packageNameController.text,
          'address': _addressController.text,
          'latitude': double.parse(_latController.text),
          'longitude': double.parse(_lonController.text),
          'deadline': _deadlineController.text,
          'size': _selectedSize,
          'priority': 0,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Package added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        _clearFields();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  void _clearFields() {
    _packageIdController.clear();
    _packageNameController.clear();
    _addressController.clear();
    _latController.clear();
    _lonController.clear();
    _deadlineController.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Package'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildTextField(_packageIdController,
                'Package ID', Icons.qr_code),
            const SizedBox(height: 16),
            _buildTextField(_packageNameController,
                'Package Name', Icons.inventory),
            const SizedBox(height: 16),
            _buildTextField(_addressController,
                'Delivery Address', Icons.location_on),
            const SizedBox(height: 16),
            _buildTextField(_latController,
                'Latitude', Icons.map,
                isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(_lonController,
                'Longitude', Icons.map,
                isNumber: true),
            const SizedBox(height: 16),
            _buildTextField(_deadlineController,
                'Deadline (HH:mm)', Icons.access_time),
            const SizedBox(height: 16),
            // Size dropdown
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedSize,
                  isExpanded: true,
                  items: ['SMALL', 'MEDIUM', 'LARGE']
                      .map((size) => DropdownMenuItem(
                    value: size,
                    child: Text(size),
                  ))
                      .toList(),
                  onChanged: (val) =>
                      setState(() => _selectedSize = val!),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _addPackage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1565C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(
                    color: Colors.white)
                    : const Text('Add Package',
                    style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(
      TextEditingController controller, String label, IconData icon,
      {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber
          ? TextInputType.number
          : TextInputType.text,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}