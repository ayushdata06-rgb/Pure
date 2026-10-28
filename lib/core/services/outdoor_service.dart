import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import '../../data/models/outdoor_data.dart';

class OutdoorService {
  OutdoorService._();
  static final OutdoorService instance = OutdoorService._();

  OutdoorData _latest = OutdoorData.initial();
  OutdoorData get latest => _latest;

  /// Fetch GPS location and live Open-Meteo ambient weather & AQI
  Future<OutdoorData> fetchOutdoorData() async {
    try {
      Position? position;
      
      // 1. Verify and request GPS permission safely
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.whileInUse ||
          permission == LocationPermission.always) {
        position = await Geolocator.getLastKnownPosition();
        position ??= await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.low,
          timeLimit: const Duration(seconds: 4),
        );
      }

      final lat = position?.latitude ?? 28.6139; // Default fallback New Delhi
      final lon = position?.longitude ?? 77.2090;

      // 2. Fetch Open-Meteo Ambient Weather (Temp, Humidity)
      final weatherRes = await http.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,relative_humidity_2m',
        ),
      ).timeout(const Duration(seconds: 5));

      // 3. Fetch Open-Meteo Ambient Air Quality (US AQI & PM2.5)
      final aqiRes = await http.get(
        Uri.parse(
          'https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&current=us_aqi,pm2_5',
        ),
      ).timeout(const Duration(seconds: 5));

      double temp = _latest.temperature;
      double humidity = _latest.humidity;
      int aqi = _latest.aqi;
      double pm25 = _latest.pm25;

      if (weatherRes.statusCode == 200) {
        final weatherJson = jsonDecode(weatherRes.body) as Map<String, dynamic>;
        final current = weatherJson['current'] as Map<String, dynamic>?;
        if (current != null) {
          temp = (current['temperature_2m'] as num?)?.toDouble() ?? temp;
          humidity = (current['relative_humidity_2m'] as num?)?.toDouble() ?? humidity;
        }
      }

      if (aqiRes.statusCode == 200) {
        final aqiJson = jsonDecode(aqiRes.body) as Map<String, dynamic>;
        final current = aqiJson['current'] as Map<String, dynamic>?;
        if (current != null) {
          aqi = (current['us_aqi'] as num?)?.toInt() ?? aqi;
          pm25 = (current['pm2_5'] as num?)?.toDouble() ?? pm25;
        }
      }

      final cityName = position != null
          ? 'GPS (${lat.toStringAsFixed(2)}°, ${lon.toStringAsFixed(2)}°)'
          : 'Ambient Baseline';

      _latest = OutdoorData(
        cityName: cityName,
        temperature: temp,
        humidity: humidity,
        aqi: aqi,
        pm25: pm25,
        timestamp: DateTime.now(),
      );

      debugPrint('[OutdoorService] Outdoor data refreshed: AQI $aqi, Temp: $temp°C, Hum: $humidity%');
      return _latest;
    } catch (e) {
      debugPrint('[OutdoorService] Notice fetching outdoor data: $e');
      return _latest;
    }
  }
}
