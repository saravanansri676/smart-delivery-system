import 'package:http/http.dart' as http;
import 'dart:convert';

class WeatherService {
  final String apiKey = '4e542e2c0b723b433373c1e5f29aa465';
  final String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Get weather for a location
  Future<Map<String, dynamic>> getWeather(
      double lat, double lon) async {
    try {
      final response = await http.get(Uri.parse(
          '$baseUrl/weather?lat=$lat&lon=$lon'
              '&appid=$apiKey&units=metric'));

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Weather API error: $e');
    }
    return {};
  }

  // Get weather warning for driver
  String getWeatherWarning(Map<String, dynamic> weather) {
    if (weather.isEmpty) return '';

    String condition =
    weather['weather'][0]['main'].toString().toLowerCase();
    double windSpeed = weather['wind']['speed'].toDouble();
    String cityName = weather['name'] ?? '';
    double temp = weather['main']['temp'].toDouble();

    // Check dangerous conditions
    if (condition.contains('thunderstorm')) {
      return '⛈ THUNDERSTORM WARNING in $cityName! '
          'Avoid delivery if possible.';
    } else if (condition.contains('tornado')) {
      return '🌪 TORNADO WARNING! Stop delivery immediately.';
    } else if (condition.contains('snow')) {
      return '❄ SNOW WARNING in $cityName! '
          'Drive carefully, roads may be slippery.';
    } else if (condition.contains('rain') && windSpeed > 10) {
      return '🌧 HEAVY RAIN in $cityName! '
          'Reduce speed. Package protection needed.';
    } else if (condition.contains('rain')) {
      return '🌦 Light rain in $cityName. '
          'Keep packages covered.';
    } else if (windSpeed > 15) {
      return '💨 Strong winds in $cityName! '
          'Drive carefully.';
    } else if (temp > 40) {
      return '🌡 Extreme heat (${temp}°C)! '
          'Stay hydrated.';
    }

    return '✅ Weather clear in $cityName. '
        'Good conditions for delivery!';
  }

  // Get weather icon
  String getWeatherIcon(Map<String, dynamic> weather) {
    if (weather.isEmpty) return '🌤';
    String condition =
    weather['weather'][0]['main'].toString().toLowerCase();

    if (condition.contains('thunderstorm')) return '⛈';
    if (condition.contains('rain')) return '🌧';
    if (condition.contains('snow')) return '❄';
    if (condition.contains('cloud')) return '☁';
    if (condition.contains('clear')) return '☀';
    if (condition.contains('mist') ||
        condition.contains('fog')) return '🌫';
    return '🌤';
  }

  // Check if weather is dangerous for delivery
  bool isDangerousWeather(Map<String, dynamic> weather) {
    if (weather.isEmpty) return false;
    String condition =
    weather['weather'][0]['main'].toString().toLowerCase();
    double windSpeed = weather['wind']['speed'].toDouble();

    return condition.contains('thunderstorm') ||
        condition.contains('tornado') ||
        (condition.contains('rain') && windSpeed > 10);
  }
}