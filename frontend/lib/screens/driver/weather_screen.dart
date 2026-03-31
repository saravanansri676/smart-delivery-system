import 'package:flutter/material.dart';
import '../../services/weather_service.dart';

class WeatherScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  const WeatherScreen({
    super.key,
    required this.latitude,
    required this.longitude,
  });

  @override
  State<WeatherScreen> createState() => _WeatherScreenState();
}

class _WeatherScreenState extends State<WeatherScreen> {
  Map<String, dynamic> weatherData = {};
  bool isLoading = true;
  final WeatherService weatherService = WeatherService();

  @override
  void initState() {
    super.initState();
    fetchWeather();
  }

  Future<void> fetchWeather() async {
    final data = await weatherService.getWeather(
        widget.latitude, widget.longitude);
    setState(() {
      weatherData = data;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Status'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : weatherData.isEmpty
          ? const Center(child: Text('Could not fetch weather'))
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Main weather card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1565C0),
                    Color(0xFF1E88E5)
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius:
                BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Text(
                    weatherService
                        .getWeatherIcon(weatherData),
                    style: const TextStyle(
                        fontSize: 60),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${weatherData['main']['temp']
                        .toStringAsFixed(1)}°C',
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    weatherData['weather'][0]['description']
                        .toString()
                        .toUpperCase(),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                  Text(
                    weatherData['name'] ?? '',
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Weather details
            Row(
              children: [
                _buildDetailCard(
                  'Humidity',
                  '${weatherData['main']['humidity']}%',
                  Icons.water_drop,
                  Colors.blue,
                ),
                const SizedBox(width: 12),
                _buildDetailCard(
                  'Wind Speed',
                  '${weatherData['wind']['speed']} m/s',
                  Icons.air,
                  Colors.teal,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildDetailCard(
                  'Feels Like',
                  '${weatherData['main']['feels_like']
                      .toStringAsFixed(1)}°C',
                  Icons.thermostat,
                  Colors.orange,
                ),
                const SizedBox(width: 12),
                _buildDetailCard(
                  'Visibility',
                  '${((weatherData['visibility'] ?? 0) / 1000)
                      .toStringAsFixed(1)} km',
                  Icons.visibility,
                  Colors.purple,
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Warning banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: weatherService
                    .isDangerousWeather(weatherData)
                    ? Colors.red.shade50
                    : Colors.green.shade50,
                borderRadius:
                BorderRadius.circular(12),
                border: Border.all(
                  color: weatherService
                      .isDangerousWeather(weatherData)
                      ? Colors.red.shade200
                      : Colors.green.shade200,
                ),
              ),
              child: Text(
                weatherService
                    .getWeatherWarning(weatherData),
                style: TextStyle(
                  fontSize: 14,
                  color: weatherService
                      .isDangerousWeather(weatherData)
                      ? Colors.red.shade700
                      : Colors.green.shade700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailCard(String title, String value,
      IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
            )
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 12, color: Colors.grey)),
                Text(value,
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: color)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}