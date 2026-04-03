import 'package:http/http.dart' as http;
import 'dart:convert';

class GeocodingService {
  Future<List<Map<String, dynamic>>> searchAddress(
      String query) async {
    if (query.length < 3) return [];

    try {
      // Try multiple search strategies
      final urls = [
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query + ", India")}'
            '&format=json&addressdetails=1&limit=5',
        'https://nominatim.openstreetmap.org/search'
            '?q=${Uri.encodeComponent(query)}'
            '&format=json&addressdetails=1&limit=5'
            '&countrycodes=in',
      ];

      for (final url in urls) {
        final response = await http.get(
          Uri.parse(url),
          headers: {
            'User-Agent': 'SmartDelivery/1.0',
            'Accept': 'application/json',
          },
        ).timeout(const Duration(seconds: 10));

        print('URL: $url');
        print('Status: ${response.statusCode}');
        print('Body length: ${response.body.length}');

        if (response.statusCode == 200) {
          final List data = jsonDecode(response.body);
          print('Results count: ${data.length}');

          if (data.isNotEmpty) {
            return data.map((item) {
              final addr = item['address'] ?? {};
              return {
                'display_name': item['display_name'] ?? '',
                'lat': double.parse(
                    item['lat'].toString()),
                'lon': double.parse(
                    item['lon'].toString()),
                'city': addr['city'] ??
                    addr['town'] ??
                    addr['village'] ??
                    addr['county'] ?? '',
                'state': addr['state'] ?? '',
                'postcode': addr['postcode'] ?? '',
              };
            }).toList();
          }
        }
      }
    } catch (e) {
      print('Geocoding exception: $e');
    }
    return [];
  }
}