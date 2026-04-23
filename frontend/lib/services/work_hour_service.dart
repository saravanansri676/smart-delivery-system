import 'dart:async';
import 'package:http/http.dart' as http;

/// Runs a periodic timer that checks the current time
/// every minute. When the current time passes the driver's
/// work end time (16:00), it automatically sets their
/// status to OFFLINE.
///
/// Start this service after driver login.
/// Cancel it on logout.
class WorkHourService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  Timer? _timer;
  final String driverId;
  final String workEndTime; // format: "HH:mm"

  // Callback so UI can update when status changes
  final void Function(String newStatus)? onStatusChanged;

  WorkHourService({
    required this.driverId,
    this.workEndTime = '16:00',
    this.onStatusChanged,
  });

  // ── Start monitoring ────────────────────────────────────
  void start() {
    // Check immediately on start
    _checkAndUpdate();

    // Then check every minute
    _timer = Timer.periodic(
      const Duration(minutes: 1),
          (_) => _checkAndUpdate(),
    );
  }

  // ── Stop monitoring ─────────────────────────────────────
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  // ── Check current time vs work end time ─────────────────
  Future<void> _checkAndUpdate() async {
    final now = DateTime.now();
    final parts = workEndTime.split(':');
    if (parts.length != 2) return;

    final endHour = int.tryParse(parts[0]) ?? 16;
    final endMinute = int.tryParse(parts[1]) ?? 0;

    final workEnd = DateTime(
        now.year, now.month, now.day, endHour, endMinute);

    // If current time is past work end → set OFFLINE
    if (now.isAfter(workEnd)) {
      await _setOffline();
    }
  }

  Future<void> _setOffline() async {
    try {
      final response = await http.put(Uri.parse(
          '$baseUrl/drivers/status/$driverId'
              '?status=OFFLINE'));

      if (response.statusCode == 200) {
        onStatusChanged?.call('OFFLINE');
        // Stop timer — no need to keep checking
        stop();
      }
    } catch (e) {
      // Silent fail — will retry next minute
    }
  }
}