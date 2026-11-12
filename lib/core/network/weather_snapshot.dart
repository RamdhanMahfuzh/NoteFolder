String weatherDescription(int? code) {
  if (code == null) return 'Conditions unavailable';
  if (code == 0) return 'Clear';
  if (code <= 3) return 'Partly cloudy';
  if (code == 45 || code == 48) return 'Fog';
  if (code <= 67 || code == 80 || code == 81 || code == 82) return 'Rain';
  if (code <= 77 || code == 85 || code == 86) return 'Snow';
  if (code >= 95) return 'Thunderstorm';
  return 'Cloudy';
}

String weatherNoteEntry(Map<String, dynamic> data) {
  final current = data['current'] as Map<String, dynamic>?;
  final temperature = current?['temperature_2m'] as num?;
  if (temperature == null) {
    throw const FormatException('Weather response has no current temperature');
  }

  final code = (current?['weather_code'] as num?)?.toInt();
  return '${weatherDescription(code)} · ${temperature.round()}°C';
}
