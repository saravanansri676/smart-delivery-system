import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/app_config.dart';

class DepotService {
  static double get defaultLat =>
      AppConfig.defaultLatitude;
  static double get defaultLon =>
      AppConfig.defaultLongitude;

  /// Returns [latitude, longitude] for the given manager's depot.
  /// Falls back to Coimbatore defaults if not set.
  static Future<List<double>> getDepotCoords(
      String managerId) async {
    try {
      final response = await http
          .get(Uri.parse(
          '${AppConfig.baseUrl}/depot/$managerId'))
          .timeout(AppConfig.receiveTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body)
        as Map<String, dynamic>;
        final lat =
        (data['latitude'] as num?)?.toDouble();
        final lon =
        (data['longitude'] as num?)?.toDouble();
        if (lat != null && lon != null) {
          return [lat, lon];
        }
      }
    } catch (e) {
      // Fall through to defaults
    }
    return [defaultLat, defaultLon];
  }
}