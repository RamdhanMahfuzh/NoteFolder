import 'package:dio/dio.dart';

class WeatherService {
  WeatherService(this._dio);

  final Dio _dio;

  Future<Map<String, dynamic>> getWeather({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      'https://api.open-meteo.com/v1/forecast',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'current':
            'temperature_2m,relative_humidity_2m,'
            'apparent_temperature,weather_code,wind_speed_10m',
        'daily': 'weather_code,temperature_2m_max,temperature_2m_min',
        'timezone': 'auto',
      },
    );
    final data = response.data;
    if (data == null) {
      throw const FormatException('Weather response was empty');
    }
    return data;
  }
}
