import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../services/geocoding_service.dart';
import 'dart:async';

class DepotSettingsScreen extends StatefulWidget {
  final String managerId;

  const DepotSettingsScreen(
      {super.key, required this.managerId});

  @override
  State<DepotSettingsScreen> createState() =>
      _DepotSettingsScreenState();
}

class _DepotSettingsScreenState
    extends State<DepotSettingsScreen> {
  final _depotNameController = TextEditingController();
  final _addressSearchController =
  TextEditingController();

  bool _isLoading = false;
  bool _isSaving = false;
  bool _isSearching = false;

  Map<String, dynamic>? _currentDepot;
  Map<String, dynamic>? _selectedLocation;
  List<Map<String, dynamic>> _suggestions = [];
  bool _showSuggestions = false;
  Timer? _debounce;

  final GeocodingService _geocodingService =
  GeocodingService();
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _loadCurrentDepot();
  }

  // ── Load existing depot from backend ────────────────────
  Future<void> _loadCurrentDepot() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/depot/${widget.managerId}'));
      if (response.statusCode == 200 &&
          response.body != 'null' &&
          response.body.isNotEmpty) {
        final data =
        jsonDecode(response.body) as Map<String, dynamic>;
        setState(() {
          _currentDepot = data;
          _depotNameController.text =
              data['depotName'] ?? '';
          // Show current address in search field
          _addressSearchController.text =
              data['address'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Load depot error: $e');
    }
    setState(() => _isLoading = false);
  }

  // ── Address autocomplete ─────────────────────────────────
  void _onSearchChanged(String query) {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce =
        Timer(const Duration(milliseconds: 600), () {
          if (query.length >= 3) {
            _searchAddress(query);
          } else {
            setState(() {
              _suggestions = [];
              _showSuggestions = false;
            });
          }
        });
  }

  Future<void> _searchAddress(String query) async {
    setState(() => _isSearching = true);
    final results =
    await _geocodingService.searchAddress(query);
    setState(() {
      _suggestions = results;
      _showSuggestions = results.isNotEmpty;
      _isSearching = false;
    });
  }

  void _selectLocation(Map<String, dynamic> location) {
    setState(() {
      _selectedLocation = location;
      _addressSearchController.text =
      location['display_name'];
      _showSuggestions = false;
      _suggestions = [];
    });
  }

  // ── Save depot to backend ────────────────────────────────
  Future<void> _saveDepot() async {
    if (_depotNameController.text.trim().isEmpty) {
      _showError('Please enter a depot name');
      return;
    }

    // If no new location selected, check if existing
    if (_selectedLocation == null &&
        _currentDepot == null) {
      _showError(
          'Please search and select a depot location');
      return;
    }

    setState(() => _isSaving = true);

    try {
      double lat;
      double lon;
      String address;

      if (_selectedLocation != null) {
        // Use newly selected location
        lat = (_selectedLocation!['lat'] as num)
            .toDouble();
        lon = (_selectedLocation!['lon'] as num)
            .toDouble();
        address =
            _selectedLocation!['display_name'] ?? '';
      } else {
        // Keep existing depot coordinates
        lat = (_currentDepot!['latitude'] as num)
            .toDouble();
        lon = (_currentDepot!['longitude'] as num)
            .toDouble();
        address = _currentDepot!['address'] ?? '';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/depot/save'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'managerId': widget.managerId,
          'depotName':
          _depotNameController.text.trim(),
          'latitude': lat,
          'longitude': lon,
          'address': address,
        }),
      );

      if (response.statusCode == 200 &&
          response.body.startsWith('Depot saved')) {
        // Reload to confirm saved data
        await _loadCurrentDepot();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Depot location saved successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        _showError('Failed to save. Try again.');
      }
    } catch (e) {
      _showError('Connection error.');
    }

    setState(() => _isSaving = false);
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
    _debounce?.cancel();
    _depotNameController.dispose();
    _addressSearchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Depot / Warehouse Settings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(
          child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment:
          CrossAxisAlignment.start,
          children: [
            // Current depot info banner
            if (_currentDepot != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.only(
                    bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius:
                  BorderRadius.circular(14),
                  border: Border.all(
                      color:
                      Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.warehouse_rounded,
                          color: Colors.green,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Current Depot',
                          style: TextStyle(
                            fontWeight:
                            FontWeight.w700,
                            color: Colors.green,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _currentDepot![
                      'depotName'] ??
                          'Unnamed',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _currentDepot!['address'] ??
                          '',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Lat: ${(_currentDepot!['latitude'] as num).toStringAsFixed(4)}, '
                          'Lon: ${(_currentDepot!['longitude'] as num).toStringAsFixed(4)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontFamily: 'monospace',
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),

            // Section header
            Row(
              children: [
                const Icon(
                  Icons.edit_location_rounded,
                  color: Color(0xFF0D47A1),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _currentDepot == null
                      ? 'Set Depot Location'
                      : 'Update Depot Location',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF0D47A1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Form card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color:
                    Colors.grey.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Depot name
                  TextFormField(
                    controller:
                    _depotNameController,
                    decoration: InputDecoration(
                      labelText: 'Depot Name',
                      hintText:
                      'e.g. Main Warehouse',
                      prefixIcon: const Icon(
                        Icons.warehouse_rounded,
                        color: Color(0xFF0D47A1),
                      ),
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                            12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Address search
                  TextFormField(
                    controller:
                    _addressSearchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      labelText:
                      'Search Depot Location',
                      hintText:
                      'Type area or city...',
                      prefixIcon: const Icon(
                        Icons.search_rounded,
                        color: Color(0xFF0D47A1),
                      ),
                      suffixIcon: _isSearching
                          ? const Padding(
                        padding:
                        EdgeInsets.all(
                            12),
                        child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                          CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(
                                0xFF0D47A1),
                          ),
                        ),
                      )
                          : _selectedLocation !=
                          null
                          ? const Icon(
                          Icons
                              .check_circle_rounded,
                          color:
                          Colors.green)
                          : null,
                      border: OutlineInputBorder(
                        borderRadius:
                        BorderRadius.circular(
                            12),
                      ),
                    ),
                  ),

                  // Suggestions dropdown
                  if (_showSuggestions &&
                      _suggestions.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(
                          top: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                        BorderRadius.circular(
                            12),
                        border: Border.all(
                            color: Colors
                                .grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.grey
                                .withOpacity(0.15),
                            blurRadius: 8,
                            offset:
                            const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics:
                        const NeverScrollableScrollPhysics(),
                        itemCount:
                        _suggestions.length,
                        separatorBuilder: (_, __) =>
                            Divider(
                                height: 1,
                                color: Colors
                                    .grey.shade100),
                        itemBuilder:
                            (context, index) {
                          final s =
                          _suggestions[index];
                          return ListTile(
                            leading: const Icon(
                              Icons
                                  .location_on_rounded,
                              color:
                              Color(0xFF0D47A1),
                              size: 20,
                            ),
                            title: Text(
                              s['display_name'],
                              style: const TextStyle(
                                  fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow
                                  .ellipsis,
                            ),
                            onTap: () =>
                                _selectLocation(s),
                            dense: true,
                          );
                        },
                      ),
                    ),

                  // Selected location preview
                  if (_selectedLocation != null)
                    Container(
                      margin: const EdgeInsets.only(
                          top: 12),
                      padding:
                      const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F4FF),
                        borderRadius:
                        BorderRadius.circular(
                            10),
                        border: Border.all(
                          color: const Color(
                              0xFF0D47A1)
                              .withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Selected Location:',
                            style: TextStyle(
                              fontSize: 12,
                              color:
                              Color(0xFF0D47A1),
                              fontWeight:
                              FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Lat: ${(_selectedLocation!['lat'] as num).toStringAsFixed(4)}, '
                                'Lon: ${(_selectedLocation!['lon'] as num).toStringAsFixed(4)}',
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color:
                              Color(0xFF0D47A1),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Save button
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed:
                _isSaving ? null : _saveDepot,
                icon: _isSaving
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child:
                  CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(
                    Icons.save_rounded),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : 'Save Depot Location',
                  style: const TextStyle(
                    fontSize: 16,
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
            const SizedBox(height: 12),

            // Info note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                    color: Colors.blue.shade100),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline_rounded,
                      color: Colors.blue.shade700,
                      size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'This location is used as the '
                          'starting point for all route '
                          'optimisation, fuel checks, '
                          'and time window calculations.',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}