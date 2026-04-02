import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class AddPackageScreen extends StatefulWidget {
  const AddPackageScreen({super.key});

  @override
  State<AddPackageScreen> createState() =>
      _AddPackageScreenState();
}

final GlobalKey _qrKey = GlobalKey();

class _AddPackageScreenState extends State<AddPackageScreen> {
  final _formKey = GlobalKey<FormState>();
  final _packageNameController = TextEditingController();
  final _receiverNameController = TextEditingController();
  final _receiverPhoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _weightController = TextEditingController();

  String _selectedSize = 'SMALL';
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isLoading = false;
  String? _generatedPackageId;
  Map<String, dynamic>? _addedPackage;

  final String baseUrl = 'http://10.0.2.2:8080';

  // Auto generate package ID
  String _generatePackageId() {
    final now = DateTime.now();
    return 'PKG${now.year}${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}'
        '${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1),
            ),
          ),
          child: child!,
        );
      },
    );
    if (date != null) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF0D47A1),
            ),
          ),
          child: child!,
        );
      },
    );
    if (time != null) setState(() => _selectedTime = time);
  }

  Future<void> _addPackage() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select deadline date and time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final packageId = _generatePackageId();
    final deadlineTime =
        '${_selectedTime!.hour.toString().padLeft(2, '0')}'
        ':${_selectedTime!.minute.toString().padLeft(2, '0')}';
    final deadlineDate =
        '${_selectedDate!.year}-'
        '${_selectedDate!.month.toString().padLeft(2, '0')}-'
        '${_selectedDate!.day.toString().padLeft(2, '0')} '
        '$deadlineTime';

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/packages/add'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'packageId': packageId,
          'packageName': _packageNameController.text,
          'receiverName': _receiverNameController.text,
          'receiverPhone': _receiverPhoneController.text,
          'address': _addressController.text,
          'latitude': 0.0,
          'longitude': 0.0,
          'deadline': deadlineTime,
          'deadlineDate': deadlineDate,
          'weightKg': double.tryParse(
              _weightController.text) ??
              0.0,
          'size': _selectedSize,
          'priority': 0,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _generatedPackageId = packageId;
          _addedPackage = {
            'packageId': packageId,
            'packageName': _packageNameController.text,
            'receiverName': _receiverNameController.text,
            'receiverPhone': _receiverPhoneController.text,
            'address': _addressController.text,
            'deadlineDate': deadlineDate,
            'size': _selectedSize,
            'weightKg': _weightController.text,
          };
        });
        _showQRDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }

    setState(() => _isLoading = false);
  }

  void _showQRDialog() {
    final qrData = jsonEncode(_addedPackage);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.8,
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
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
                    'Package Added!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),

                  const SizedBox(height: 4),

                  Text(
                    _generatedPackageId ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                      fontFamily: 'monospace',
                    ),
                  ),

                  const SizedBox(height: 20),

                  // QR Code
                  RepaintBoundary(
                    key: _qrKey,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.white,
                      child: Column(
                        children: [
                          QrImageView(
                            data: qrData,
                            version: QrVersions.auto,
                            size: 180,
                            backgroundColor: Colors.white,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _generatedPackageId ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                              color: Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Download button
                  TextButton.icon(
                    onPressed: _downloadQR,
                    icon: const Icon(Icons.download_rounded,
                        color: Color(0xFF0D47A1)),
                    label: const Text(
                      'Download QR Code',
                      style: TextStyle(color: Color(0xFF0D47A1)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Text(
                    'Scan to view package details',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),

                  const SizedBox(height: 8),

                  //  Package info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      children: [
                        _buildInfoRow('Receiver',
                            _addedPackage!['receiverName']),
                        _buildInfoRow('Phone',
                            _addedPackage!['receiverPhone']),
                        _buildInfoRow('Address',
                            _addedPackage!['address']),
                        _buildInfoRow('Deadline',
                            _addedPackage!['deadlineDate']),
                        _buildInfoRow('Size',
                            _addedPackage!['size']),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  const Text(
                    'Print this QR code and paste on package',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF0D47A1),
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 16),

                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            _clearFields();
                          },
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Add Another'),
                        ),
                      ),

                      const SizedBox(width: 12),

                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(context);
                            Navigator.pop(context);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0D47A1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Done'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 70,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearFields() {
    _packageNameController.clear();
    _receiverNameController.clear();
    _receiverPhoneController.clear();
    _addressController.clear();
    _weightController.clear();
    setState(() {
      _selectedDate = null;
      _selectedTime = null;
      _selectedSize = 'SMALL';
      _generatedPackageId = null;
      _addedPackage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Add Package'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Package Info Section
              _buildSectionHeader(
                  'Package Information', Icons.inventory_2_rounded),
              const SizedBox(height: 12),
              _buildCard([
                _buildFormField(
                  controller: _packageNameController,
                  label: 'Package Name',
                  hint: 'e.g. Laptop, Books, Clothes',
                  icon: Icons.inventory_rounded,
                  isAlphaOnly: true,
                  validator: (v) => v!.isEmpty
                      ? 'Package name required' : null,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _buildFormField(
                        controller: _weightController,
                        label: 'Weight (kg)',
                        hint: 'e.g. 2.5',
                        icon: Icons.scale_rounded,
                        isNumber: true,
                        validator: (v) => v!.isEmpty
                            ? 'Weight required' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text('Size',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey,
                                fontWeight: FontWeight.w500,
                              )),
                          const SizedBox(height: 8),
                          Container(
                            padding:
                            const EdgeInsets.symmetric(
                                horizontal: 12),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              borderRadius:
                              BorderRadius.circular(12),
                              border: Border.all(
                                  color: Colors.grey.shade300),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedSize,
                                isExpanded: true,
                                items: ['SMALL', 'MEDIUM', 'LARGE']
                                    .map((s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(s),
                                ))
                                    .toList(),
                                onChanged: (val) => setState(
                                        () => _selectedSize = val!),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 20),

              // Receiver Info Section
              _buildSectionHeader(
                  'Receiver Information', Icons.person_rounded),
              const SizedBox(height: 12),
              _buildCard([
                _buildFormField(
                  controller: _receiverNameController,
                  label: 'Receiver Name',
                  hint: 'Full name of receiver',
                  icon: Icons.person_rounded,
                  isAlphaOnly: true,
                  validator: (v) => v!.isEmpty
                      ? 'Receiver name required' : null,
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _receiverPhoneController,
                  label: 'Phone Number',
                  hint: 'e.g. 9876543210',
                  icon: Icons.phone_rounded,
                  isNumber: true,
                  validator: (v) {
                    if (v!.isEmpty) return 'Phone required';
                    if (v.length != 10)
                      return 'Enter valid 10 digit number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildFormField(
                  controller: _addressController,
                  label: 'Delivery Address',
                  hint: 'Complete address with city',
                  icon: Icons.location_on_rounded,
                  maxLines: 3,
                  validator: (v) => v!.isEmpty
                      ? 'Address required' : null,
                ),
              ]),
              const SizedBox(height: 20),

              // Deadline Section
              _buildSectionHeader(
                  'Delivery Deadline', Icons.schedule_rounded),
              const SizedBox(height: 12),
              _buildCard([
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickDate,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius:
                            BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.calendar_today_rounded,
                                color: Color(0xFF0D47A1),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : '${_selectedDate!.day}/'
                                    '${_selectedDate!.month}/'
                                    '${_selectedDate!.year}',
                                style: TextStyle(
                                  color: _selectedDate == null
                                      ? Colors.grey
                                      : const Color(0xFF1A1A2E),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: GestureDetector(
                        onTap: _pickTime,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius:
                            BorderRadius.circular(12),
                            border: Border.all(
                                color: Colors.grey.shade300),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                color: Color(0xFF0D47A1),
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                _selectedTime == null
                                    ? 'Select Time'
                                    : _selectedTime!
                                    .format(context),
                                style: TextStyle(
                                  color: _selectedTime == null
                                      ? Colors.grey
                                      : const Color(0xFF1A1A2E),
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ]),
              const SizedBox(height: 32),

              // Submit button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _addPackage,
                  icon: _isLoading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : const Icon(Icons.add_box_rounded),
                  label: Text(
                    _isLoading ? 'Adding...' : 'Add Package & Generate QR',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF0D47A1), size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D47A1),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Container(
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
        children: children,
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool isNumber = false,
    bool isAlphaOnly = false,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber
          ? const TextInputType.numberWithOptions(decimal: true)
          : TextInputType.multiline,
      maxLines: maxLines,
      validator: validator,
      inputFormatters: isNumber
          ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
          : isAlphaOnly
          ? [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-Z\s]'))]
          : null,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: const Color(0xFF0D47A1)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
  Future<void> _downloadQR() async {
    try {
      RenderRepaintBoundary boundary = _qrKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(
          format: ui.ImageByteFormat.png);
      final pngBytes = byteData!.buffer.asUint8List();

      final directory = await getExternalStorageDirectory();
      final path = '${directory!.path}/'
          '${_generatedPackageId}_QR.png';
      final file = File(path);
      await file.writeAsBytes(pngBytes);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('QR saved to: $path'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving QR: $e')),
      );
    }
  }
}