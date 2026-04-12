import 'package:http/http.dart' as http;
import 'dart:convert';

/// Shared service used by all screens that need the
/// depot (warehouse) start coordinates.
///
/// Previously every screen hardcoded:
///   startLat=13.0827&startLon=80.2707
///
/// Now all screens call DepotService.getDepot(managerId)
/// to get the manager's configured depot location.
///
/// Falls back to Chennai default if depot not set yet.
class DepotService {
  static const String baseUrl = 'http://10.0.2.2:8080';

  // Default fallback coordinates (Chennai)
  // Used when manager has not yet configured depot
  static const double defaultLat = 13.0827;
  static const double defaultLon = 80.2707;

  /// Fetch depot coordinates for a manager.
  /// Returns [lat, lon] — never null.
  /// Falls back to Chennai default if not configured.
  static Future<List<double>> getDepotCoords(
      String managerId) async {
    try {
      if (managerId.isEmpty) {
        return [defaultLat, defaultLon];
      }

      final response = await http.get(
        Uri.parse('$baseUrl/depot/$managerId'),
      );

      if (response.statusCode == 200 &&
          response.body.isNotEmpty &&
          response.body != 'null') {
        final data = jsonDecode(response.body)
        as Map<String, dynamic>;
        final lat =
        (data['latitude'] as num).toDouble();
        final lon =
        (data['longitude'] as num).toDouble();
        return [lat, lon];
      }
    } catch (e) {
      // Silent fallback — don't crash the screen
    }

    // Return default if anything goes wrong
    return [defaultLat, defaultLon];
  }
}