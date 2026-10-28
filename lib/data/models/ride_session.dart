class RideDataPoint {
  final DateTime timestamp;
  final int insideAqi;
  final int outsideAqi;
  final double temperature;
  final double humidity;

  const RideDataPoint({
    required this.timestamp,
    required this.insideAqi,
    required this.outsideAqi,
    required this.temperature,
    required this.humidity,
  });

  Map<String, dynamic> toMap() => {
        'timestamp': timestamp.toIso8601String(),
        'inside_aqi': insideAqi,
        'outside_aqi': outsideAqi,
        'temp_c': temperature,
        'humidity_pct': humidity,
      };

  factory RideDataPoint.fromMap(Map<String, dynamic> map) => RideDataPoint(
        timestamp: DateTime.tryParse(map['timestamp'] ?? '') ?? DateTime.now(),
        insideAqi: (map['inside_aqi'] ?? 25) as int,
        outsideAqi: (map['outside_aqi'] ?? 100) as int,
        temperature: ((map['temp_c'] ?? 28.0) as num).toDouble(),
        humidity: ((map['humidity_pct'] ?? 60.0) as num).toDouble(),
      );
}

class RideSession {
  final String id;
  final DateTime startTime;
  final DateTime? endTime;
  final Duration duration;
  final double averageInsideAqi;
  final double averageOutsideAqi;
  final double averageTemperature;
  final double averageHumidity;
  final int cleanAirVolumeLiters;
  final int filtrationEfficiency; // Percentage (e.g. 84%)
  final bool isCompleted;
  final List<RideDataPoint> dataPoints;

  const RideSession({
    required this.id,
    required this.startTime,
    this.endTime,
    required this.duration,
    required this.averageInsideAqi,
    required this.averageOutsideAqi,
    required this.averageTemperature,
    required this.averageHumidity,
    required this.cleanAirVolumeLiters,
    required this.filtrationEfficiency,
    required this.isCompleted,
    this.dataPoints = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime?.toIso8601String(),
      'duration_seconds': duration.inSeconds,
      'avg_inside_aqi': averageInsideAqi,
      'avg_outside_aqi': averageOutsideAqi,
      'avg_temp_c': averageTemperature,
      'avg_humidity_pct': averageHumidity,
      'clean_air_liters': cleanAirVolumeLiters,
      'filtration_efficiency_pct': filtrationEfficiency,
      'is_completed': isCompleted,
      'data_points_count': dataPoints.length,
    };
  }

  factory RideSession.fromMap(Map<String, dynamic> map) {
    final start = DateTime.tryParse(map['start_time'] ?? '') ?? DateTime.now();
    final end = DateTime.tryParse(map['end_time'] ?? '');
    final durSeconds = (map['duration_seconds'] ?? 0) as int;

    return RideSession(
      id: map['id'] ?? 'session_${DateTime.now().millisecondsSinceEpoch}',
      startTime: start,
      endTime: end,
      duration: Duration(seconds: durSeconds),
      averageInsideAqi: ((map['avg_inside_aqi'] ?? 25.0) as num).toDouble(),
      averageOutsideAqi: ((map['avg_outside_aqi'] ?? 100.0) as num).toDouble(),
      averageTemperature: ((map['avg_temp_c'] ?? 28.0) as num).toDouble(),
      averageHumidity: ((map['avg_humidity_pct'] ?? 60.0) as num).toDouble(),
      cleanAirVolumeLiters: (map['clean_air_liters'] ?? 0) as int,
      filtrationEfficiency: (map['filtration_efficiency_pct'] ?? 80) as int,
      isCompleted: (map['is_completed'] ?? true) as bool,
    );
  }
}
