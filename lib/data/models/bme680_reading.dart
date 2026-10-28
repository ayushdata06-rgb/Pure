import 'package:flutter/material.dart';

/// Model representing live telemetry from the Bosch BME680 sensor on ESP32.
class Bme680Reading {
  final DateTime timestamp;
  final double temperature; // in °C
  final double humidity; // in %
  final double pressure; // in hPa
  final double gasResistance; // in KOhms
  final double altitude; // in meters

  const Bme680Reading({
    required this.timestamp,
    required this.temperature,
    required this.humidity,
    required this.pressure,
    required this.gasResistance,
    required this.altitude,
  });

  /// Inside Helmet Air Quality Index (0 - 500 equivalent)
  int get calculatedAqi {
    if (gasResistance > 80.0) return 22;
    if (gasResistance > 50.0) return 38;
    if (gasResistance > 30.0) return 65;
    if (gasResistance > 20.0) return 98;
    if (gasResistance > 10.0) return 145;
    return 210;
  }

  /// Visor Dew Point (°C) using Magnus-Tetens formula
  double get dewPoint {
    final clampedHum = humidity.clamp(1.0, 100.0);
    const a = 17.27;
    const b = 237.7;
    final alpha = ((a * temperature) / (b + temperature)) + (clampedHum > 0 ? (0.4342944819 * 2.302585 * (clampedHum / 100.0)) : 0.0);
    return (b * alpha) / (a - alpha);
  }

  /// Safety buffer above condensation temperature (°C)
  double get dewPointMargin => temperature - dewPoint;

  /// Whether visor is near condensation/fogging threshold (< 2.5°C delta)
  bool get isVisorFogRisk => dewPointMargin < 2.5;

  String get visorFogStatus => isVisorFogRisk ? 'High Fog Risk' : 'Clear & Safe';

  /// Helmet microclimate Heat Index ("Feels Like" temperature in °C)
  double get heatIndex {
    if (temperature < 20.0) return temperature;
    // Magnus-based apparent temperature equation
    final vaporPressure = (humidity / 100.0) * 6.105 * (temperature > 0 ? (1.0 + (temperature * 0.0001)) : 1.0);
    final hi = temperature + (0.33 * vaporPressure) - 0.70;
    return hi > temperature ? hi : temperature;
  }

  String get heatIndexComfort {
    if (heatIndex < 27.0) return 'Cool & Comfortable';
    if (heatIndex < 32.0) return 'Mildly Stuffy';
    if (heatIndex < 38.0) return 'High Heat Buildup';
    return 'Severe Overheating Risk';
  }

  /// Exhaled air & stale breath indicator based on VOC gas resistance
  String get staleAirStatus {
    if (gasResistance > 50.0) return 'Fresh Oxygen Circulation';
    if (gasResistance > 20.0) return 'Moderate Air (Exhaled VOCs)';
    return 'Stale Breath Accumulated';
  }

  bool get isStaleAirWarning => gasResistance <= 20.0;

  /// Non-intrusive scenario intelligence (Advisory only · does not toggle fan)
  FanAdvisory get fanAdvisory {
    if (isVisorFogRisk) {
      return FanAdvisory(
        isRecommended: true,
        badge: 'FOG HAZARD',
        title: 'Recommendation: Turn Fan ON',
        reason: 'Helmet inner shield is within ${dewPointMargin.clamp(0.1, 9.9).toStringAsFixed(1)}°C of dew point. Fan airflow will defog helmet shield.',
        color: const Color(0xFFEF4444),
      );
    } else if (heatIndex >= 32.0) {
      return FanAdvisory(
        isRecommended: true,
        badge: 'HEAT BUILDUP',
        title: 'Recommendation: Turn Fan ON',
        reason: 'Internal helmet microclimate feels like ${heatIndex.toStringAsFixed(1)}°C. Airflow recommended to prevent rider fatigue.',
        color: const Color(0xFFF97316),
      );
    } else if (isStaleAirWarning) {
      return FanAdvisory(
        isRecommended: true,
        badge: 'STALE BREATH',
        title: 'Recommendation: Ventilate Helmet',
        reason: 'Exhaled moisture and breath VOCs detected inside closed helmet. Ventilation recommended.',
        color: const Color(0xFFFBBF24),
      );
    } else {
      return const FanAdvisory(
        isRecommended: false,
        badge: 'OPTIMAL',
        title: 'Helmet Environment Optimal',
        reason: 'Helmet shield is clear, internal airflow is fresh, and temperature is comfortable. Fan can remain OFF.',
        color: Color(0xFF14B8A6),
      );
    }
  }

  String get airQualityLabel {
    if (gasResistance > 50.0) return 'Excellent Air Quality';
    if (gasResistance > 20.0) return 'Good / Normal Air';
    if (gasResistance > 10.0) return 'Moderate (VOCs Detected)';
    return 'Poor Air Quality (High Pollution)';
  }

  Map<String, dynamic> toMap() {
    return {
      'temperature_c': temperature,
      'humidity_pct': humidity,
      'pressure_hpa': pressure,
      'gas_resistance_kohm': gasResistance,
      'altitude_m': altitude,
      'air_quality_label': airQualityLabel,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Bme680Reading.fromMap(Map<String, dynamic> map) {
    return Bme680Reading(
      timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
      temperature: (map['temperature_c'] ?? 0.0).toDouble(),
      humidity: (map['humidity_pct'] ?? 0.0).toDouble(),
      pressure: (map['pressure_hpa'] ?? 0.0).toDouble(),
      gasResistance: (map['gas_resistance_kohm'] ?? 0.0).toDouble(),
      altitude: (map['altitude_m'] ?? 0.0).toDouble(),
    );
  }
}

/// Dynamic advisory model for scenario intelligence
class FanAdvisory {
  final bool isRecommended;
  final String badge;
  final String title;
  final String reason;
  final Color color;

  const FanAdvisory({
    required this.isRecommended,
    required this.badge,
    required this.title,
    required this.reason,
    required this.color,
  });
}

