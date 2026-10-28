class OutdoorData {
  final String cityName;
  final double temperature; // in °C
  final double humidity; // in %
  final int aqi; // US AQI (0 - 500)
  final double pm25; // in µg/m³
  final DateTime timestamp;

  const OutdoorData({
    required this.cityName,
    required this.temperature,
    required this.humidity,
    required this.aqi,
    required this.pm25,
    required this.timestamp,
  });

  String get aqiStatus {
    if (aqi <= 50) return 'Clean Air';
    if (aqi <= 100) return 'Moderate Air';
    if (aqi <= 150) return 'Unhealthy for Sensitive';
    if (aqi <= 200) return 'Unhealthy (Polluted)';
    return 'Hazardous Exhaust';
  }

  bool get hasData => aqi > 0 || temperature > 0.0;

  static OutdoorData initial() {
    return OutdoorData(
      cityName: 'Locating GPS...',
      temperature: 0.0,
      humidity: 0.0,
      aqi: 0,
      pm25: 0.0,
      timestamp: DateTime.now(),
    );
  }
}
