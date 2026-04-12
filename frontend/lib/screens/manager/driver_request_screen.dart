import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class DriverRequestScreen extends StatefulWidget {
  final String managerId;
  final List<dynamic> pendingRequests;
  final VoidCallback onRequestProcessed;

  const DriverRequestScreen({
    super.key,
    required this.managerId,
    required this.pendingRequests,
    required this.onRequestProcessed,
  });

  @override
  State<DriverRequestScreen> createState() =>
      _DriverRequestScreenState();
}

class _DriverRequestScreenState
    extends State<DriverRequestScreen> {
  late List<dynamic> _requests;
  final String baseUrl = 'http://10.0.2.2:8080';
  // Track which requests are being processed
  Set<String> _loadingIds = {};

  @override
  void initState() {
    super.initState();
    _requests = List.from(widget.pendingRequests);
  }

  // ── Accept request ───────────────────────────────────────
  Future<void> _accept(Map<String, dynamic> request) async {
    final requestId = request['requestId'];
    setState(() => _loadingIds.add(requestId));

    try {
      final response = await http.put(Uri.parse(
          '$baseUrl/driver-requests/accept/$requestId'));

      if (response.statusCode == 200 &&
          response.body.startsWith('ACCEPTED')) {
        final parts = response.body.split(':');
        final driverId =
        parts.length > 1 ? parts[1] : request['driverId'];
        final name =
        parts.length > 2 ? parts[2] : request['name'];

        // Remove from list
        setState(() {
          _requests.removeWhere(
                  (r) => r['requestId'] == requestId);
          _loadingIds.remove(requestId);
        });

        // Notify parent to refresh
        widget.onRequestProcessed();

        // Show success dialog
        _showSuccessDialog(driverId, name);
      } else {
        setState(() => _loadingIds.remove(requestId));
        _showError('Failed to accept request. Try again.');
      }
    } catch (e) {
      setState(() => _loadingIds.remove(requestId));
      _showError('Connection error.');
    }
  }

  // ── Reject request ───────────────────────────────────────
  Future<void> _reject(Map<String, dynamic> request) async {
    final requestId = request['requestId'];

    // Confirm before rejecting
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: const Text('Reject Request'),
        content: Text(
            'Are you sure you want to reject '
                '${request['name']}\'s registration request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loadingIds.add(requestId));

    try {
      final response = await http.put(Uri.parse(
          '$baseUrl/driver-requests/reject/$requestId'));

      if (response.statusCode == 200 &&
          response.body.startsWith('REJECTED')) {
        setState(() {
          _requests.removeWhere(
                  (r) => r['requestId'] == requestId);
          _loadingIds.remove(requestId);
        });

        widget.onRequestProcessed();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Request from ${request['name']} rejected.'),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      } else {
        setState(() => _loadingIds.remove(requestId));
        _showError('Failed to reject request. Try again.');
      }
    } catch (e) {
      setState(() => _loadingIds.remove(requestId));
      _showError('Connection error.');
    }
  }

  // ── Success dialog after acceptance ─────────────────────
  void _showSuccessDialog(String driverId, String name) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
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
                'Driver Added!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '$name has been approved and can now login.',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              // Driver ID display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F4FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF0D47A1)
                          .withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment:
                  MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.badge_rounded,
                        color: Color(0xFF0D47A1), size: 20),
                    const SizedBox(width: 8),
                    Column(
                      children: [
                        const Text(
                          'Driver ID',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                        Text(
                          driverId,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF0D47A1),
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                    const Color(0xFF0D47A1),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text('Done'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      appBar: AppBar(
        title: const Text('Driver Requests'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _requests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.check_circle_outline_rounded,
              size: 72,
              color: Colors.green.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              'All requests processed!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'No pending driver requests.',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
              ),
            ),
          ],
        ),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _requests.length,
        itemBuilder: (context, index) {
          final request = _requests[index];
          final requestId =
              request['requestId'] ?? '';
          final isLoading =
          _loadingIds.contains(requestId);

          return Container(
            margin: const EdgeInsets.only(bottom: 16),
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
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: const Color(
                          0xFF0D47A1)
                          .withOpacity(0.1),
                      child: Text(
                        (request['name'] ?? 'DR')
                            .substring(0, 1)
                            .toUpperCase(),
                        style: const TextStyle(
                          color: Color(0xFF0D47A1),
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight:
                              FontWeight.w700,
                              color: Color(0xFF1A1A2E),
                            ),
                          ),
                          Text(
                            request['driverId'] ?? '',
                            style: TextStyle(
                              fontSize: 13,
                              color:
                              Colors.grey.shade500,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Pending badge
                    Container(
                      padding:
                      const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.orange
                            .withOpacity(0.1),
                        borderRadius:
                        BorderRadius.circular(20),
                        border: Border.all(
                            color: Colors.orange
                                .withOpacity(0.4)),
                      ),
                      child: const Text(
                        'PENDING',
                        style: TextStyle(
                          color: Colors.orange,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),

                // Details
                _buildDetailRow(Icons.business_rounded,
                    'Company',
                    request['companyName'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildDetailRow(Icons.phone_rounded,
                    'Mobile',
                    request['mobileNumber'] ?? 'N/A'),
                const SizedBox(height: 8),
                _buildDetailRow(
                    Icons.access_time_rounded,
                    'Requested',
                    request['requestedAt'] ?? 'N/A'),
                const SizedBox(height: 20),

                // Accept / Reject buttons
                isLoading
                    ? const Center(
                    child:
                    CircularProgressIndicator())
                    : Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            _reject(request),
                        icon: const Icon(
                            Icons.close_rounded,
                            color: Colors.red),
                        label: const Text(
                            'Reject',
                            style: TextStyle(
                                color:
                                Colors.red)),
                        style: OutlinedButton
                            .styleFrom(
                          padding:
                          const EdgeInsets
                              .symmetric(
                              vertical: 12),
                          side: const BorderSide(
                              color: Colors.red),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () =>
                            _accept(request),
                        icon: const Icon(
                            Icons.check_rounded),
                        label: const Text(
                            'Accept'),
                        style: ElevatedButton
                            .styleFrom(
                          backgroundColor:
                          const Color(
                              0xFF2E7D32),
                          foregroundColor:
                          Colors.white,
                          padding:
                          const EdgeInsets
                              .symmetric(
                              vertical: 12),
                          shape:
                          RoundedRectangleBorder(
                            borderRadius:
                            BorderRadius
                                .circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(
      IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        SizedBox(
          width: 70,
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
    );
  }
}