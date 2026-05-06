import 'dart:async';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class WorkHourService {
  Timer? _timer;
  final String driverId;
  final String workEndTime;

  final void Function(String newStatus)? onStatusChanged;

  WorkHourService({
    required this.driverId,
    this.workEndTime = '16:00',
    this.onStatusChanged,
  });

  void start() {
    _checkAndUpdate();

    _timer = Timer.periodic(
      const Duration(minutes: 1),
          (_) => _checkAndUpdate(),
    );
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _checkAndUpdate() async {
    final now = DateTime.now();
    final parts = workEndTime.split(':');
    if (parts.length != 2) return;

    final endHour = int.tryParse(parts[0]) ?? 16;
    final endMinute = int.tryParse(parts[1]) ?? 0;

    final workEnd = DateTime(
      now.year,
      now.month,
      now.day,
      endHour,
      endMinute,
    );

    if (now.isAfter(workEnd)) {
      await _setOffline();
    }
  }

  Future<void> _setOffline() async {
    try {
      final response = await http.put(
        Uri.parse(
          '${AppConfig.baseUrl}/drivers/status/$driverId?status=OFFLINE',
        ),
      );

      if (response.statusCode == 200) {
        onStatusChanged?.call('OFFLINE');
        stop();
      }
    } catch (_) {
      // silent retry
    }
  }
}