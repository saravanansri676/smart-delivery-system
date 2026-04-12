import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../services/depot_service.dart';

class FuelStatusScreen extends StatefulWidget {
  final String driverId;
  final String managerId; // needed to fetch depot coords

  const FuelStatusScreen({
    super.key,
    required this.driverId,
    required this.managerId,
  });

  @override
  State<FuelStatusScreen> createState() =>
      _FuelStatusScreenState();
}

class _FuelStatusScreenState
    extends State<FuelStatusScreen> {
  String fuelReport = '';
  bool isLoading = true;
  double _startLat = DepotService.defaultLat;
  double _startLon = DepotService.defaultLon;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    _loadWithDepot();
  }

  // Step 1: fetch depot coords, then fetch fuel report
  Future<void> _loadWithDepot() async {
    final coords = await DepotService.getDepotCoords(
        widget.managerId);
    setState(() {
      _startLat = coords[0];
      _startLon = coords[1];
    });
    await fetchFuelReport();
  }

  Future<void> fetchFuelReport() async {
    setState(() => isLoading = true);
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/fuel/report/${widget.driverId}'
              '?startLat=$_startLat&startLon=$_startLon'));
      if (response.statusCode == 200) {
        setState(() {
          fuelReport = response.body;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        fuelReport = 'Error fetching fuel status';
        isLoading = false;
      });
    }
  }

  Future<void> updateFuel(String level) async {
    await http.put(Uri.parse(
        '$baseUrl/fuel/update/${widget.driverId}'
            '?fuelLevel=$level'));
    fetchFuelReport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuel Status'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Fuel report card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.15),
                    blurRadius: 8,
                  )
                ],
              ),
              child: isLoading
                  ? const Center(
                  child: CircularProgressIndicator())
                  : Text(fuelReport,
                  style: const TextStyle(
                      fontSize: 15)),
            ),
            const SizedBox(height: 16),

            // Depot info chip
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: Colors.blue.shade100),
              ),
              child: Text(
                'Depot: ${_startLat.toStringAsFixed(4)}, '
                    '${_startLon.toStringAsFixed(4)}',
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.blue.shade700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Update Fuel Level',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              children: [
                _fuelButton('FULL', Colors.green),
                const SizedBox(width: 10),
                _fuelButton('MID', Colors.orange),
                const SizedBox(width: 10),
                _fuelButton('LOW', Colors.red),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _fuelButton(String level, Color color) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () => updateFuel(level),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding:
          const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: Text(level,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold)),
      ),
    );
  }
}