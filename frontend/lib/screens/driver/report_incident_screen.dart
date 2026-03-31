import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ReportIncidentScreen extends StatefulWidget {
  final String driverId;
  const ReportIncidentScreen(
      {super.key, required this.driverId});

  @override
  State<ReportIncidentScreen> createState() =>
      _ReportIncidentScreenState();
}

class _ReportIncidentScreenState
    extends State<ReportIncidentScreen> {
  String _selectedIssue = 'BREAKDOWN';
  String _response = '';
  bool _isLoading = false;
  final String baseUrl = 'http://10.0.2.2:8080';

  final List<Map<String, dynamic>> issues = [
    {'label': 'Vehicle Breakdown', 'value': 'BREAKDOWN',
      'icon': Icons.car_crash, 'color': Colors.red},
    {'label': 'Flat Tyre', 'value': 'FLAT_TYRE',
      'icon': Icons.tire_repair, 'color': Colors.orange},
    {'label': 'Accident', 'value': 'ACCIDENT',
      'icon': Icons.warning, 'color': Colors.red},
    {'label': 'Fuel Empty', 'value': 'FUEL_EMPTY',
      'icon': Icons.local_gas_station, 'color': Colors.orange},
  ];

  Future<void> _reportIncident() async {
    setState(() => _isLoading = true);
    try {
      final response = await http.post(Uri.parse(
          '$baseUrl/incident/report/${widget.driverId}'
              '?issue=$_selectedIssue'));
      if (response.statusCode == 200) {
        setState(() => _response = response.body);
      }
    } catch (e) {
      setState(() => _response = 'Error: $e');
    }
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Report Incident'),
        backgroundColor: const Color(0xFFC62828),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select Issue Type',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...issues.map((issue) => GestureDetector(
              onTap: () => setState(
                      () => _selectedIssue = issue['value']),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _selectedIssue == issue['value']
                      ? (issue['color'] as Color)
                      .withOpacity(0.15)
                      : Colors.white,
                  border: Border.all(
                    color: _selectedIssue == issue['value']
                        ? issue['color'] as Color
                        : Colors.grey.shade300,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(issue['icon'] as IconData,
                        color: issue['color'] as Color),
                    const SizedBox(width: 12),
                    Text(issue['label'] as String,
                        style: const TextStyle(
                            fontSize: 16)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 20),
            if (_response.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: Colors.green.shade200),
                ),
                child: Text(_response,
                    style:
                    const TextStyle(color: Colors.green)),
              ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton.icon(
                onPressed:
                _isLoading ? null : _reportIncident,
                icon: const Icon(Icons.send),
                label: const Text('Report Incident',
                    style: TextStyle(fontSize: 18)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFC62828),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}