import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:notefolder/core/network/weather_service.dart';
import 'package:notefolder/core/network/weather_snapshot.dart';
import 'package:notefolder/injection/injection.dart' as di;

class WeatherCard extends StatefulWidget {
  const WeatherCard({super.key});

  @override
  State<WeatherCard> createState() => _WeatherCardState();
}

class _WeatherCardState extends State<WeatherCard> {
  late Future<Map<String, dynamic>> _weather;

  @override
  void initState() {
    super.initState();
    _weather = _loadWeather();
  }

  Future<Map<String, dynamic>> _loadWeather() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw Exception('Turn on location services to see local weather');
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      throw Exception('Location permission is required to show local weather');
    }
    final position = await Geolocator.getCurrentPosition();
    return di.sl<WeatherService>().getWeather(
      latitude: position.latitude,
      longitude: position.longitude,
    );
  }

  void _retry() {
    setState(() => _weather = _loadWeather());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FutureBuilder<Map<String, dynamic>>(
      future: _weather,
      builder: (context, snapshot) {
        return Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: snapshot.connectionState == ConnectionState.waiting
                ? const Center(
                    child: Padding(
                      padding: EdgeInsets.all(12),
                      child: CircularProgressIndicator(),
                    ),
                  )
                : snapshot.hasError
                ? Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Weather unavailable: ${snapshot.error}',
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        onPressed: _retry,
                        tooltip: 'Retry weather',
                        icon: const Icon(Icons.refresh),
                      ),
                    ],
                  )
                : _WeatherDetails(
                    data: snapshot.data!,
                    onSurface: colors.onSurface,
                  ),
          ),
        );
      },
    );
  }
}

class _WeatherDetails extends StatelessWidget {
  const _WeatherDetails({required this.data, required this.onSurface});

  final Map<String, dynamic> data;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    final current = data['current'] as Map<String, dynamic>?;
    final daily = data['daily'] as Map<String, dynamic>?;
    final temperature = current?['temperature_2m'] as num?;
    final apparent = current?['apparent_temperature'] as num?;
    final humidity = current?['relative_humidity_2m'] as num?;
    final wind = current?['wind_speed_10m'] as num?;
    final code = current?['weather_code'] as num?;
    final high = (daily?['temperature_2m_max'] as List?)?.firstOrNull as num?;
    final low = (daily?['temperature_2m_min'] as List?)?.firstOrNull as num?;

    if (temperature == null) {
      return const Text('Weather data unavailable');
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Weather',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Icon(_weatherIcon(code?.toInt()), size: 38, color: onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${temperature.round()}°C · ${weatherDescription(code?.toInt())}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (high != null && low != null)
                    Text('H: ${high.round()}°  L: ${low.round()}°'),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          children: [
            if (apparent != null) Text('Feels like ${apparent.round()}°C'),
            if (humidity != null) Text('Humidity ${humidity.round()}%'),
            if (wind != null) Text('Wind ${wind.round()} km/h'),
          ],
        ),
      ],
    );
  }
}

IconData _weatherIcon(int? code) {
  if (code == null) return Icons.cloud_outlined;
  if (code == 0) return Icons.wb_sunny_outlined;
  if (code <= 3) return Icons.cloud_outlined;
  if (code <= 48) return Icons.foggy;
  if (code <= 67 || (code >= 80 && code <= 82)) {
    return Icons.water_drop_outlined;
  }
  if (code <= 77 || code >= 85 && code <= 86) return Icons.ac_unit;
  if (code >= 95) return Icons.thunderstorm_outlined;
  return Icons.cloud_outlined;
}
