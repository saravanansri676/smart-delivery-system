import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ViewPackagesScreen extends StatefulWidget {
  const ViewPackagesScreen({super.key});

  @override
  State<ViewPackagesScreen> createState() =>
      _ViewPackagesScreenState();
}

class _ViewPackagesScreenState extends State<ViewPackagesScreen> {
  List packages = [];
  bool isLoading = true;
  final String baseUrl = 'http://10.0.2.2:8080';

  @override
  void initState() {
    super.initState();
    fetchPackages();
  }

  Future<void> fetchPackages() async {
    try {
      final response = await http.get(
          Uri.parse('$baseUrl/packages/all'));
      if (response.statusCode == 200) {
        setState(() {
          packages = jsonDecode(response.body);
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'IN_STORE': return Colors.blue;
      case 'ASSIGNED': return Colors.orange;
      case 'MOVING': return Colors.purple;
      case 'DELIVERED': return Colors.green;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Packages'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: fetchPackages,
          )
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : packages.isEmpty
          ? const Center(child: Text('No packages found'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: packages.length,
        itemBuilder: (context, index) {
          final pkg = packages[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: ListTile(
              leading: const Icon(Icons.inventory,
                  color: Color(0xFF1565C0)),
              title: Text(pkg['packageName'] ?? ''),
              subtitle: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(pkg['address'] ?? ''),
                  Text('Deadline: ${pkg['deadline']}'),
                ],
              ),
              trailing: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getStatusColor(
                      pkg['status'] ?? ''),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  pkg['status'] ?? '',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}