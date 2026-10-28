/// Fan speed modes for the helmet purification system.
enum FanMode { auto, low, medium, high }

/// Extension for display values
extension FanModeX on FanMode {
  String get label {
    switch (this) {
      case FanMode.auto:
        return 'Auto';
      case FanMode.low:
        return 'Low';
      case FanMode.medium:
        return 'Medium';
      case FanMode.high:
        return 'High';
    }
  }

  String get description {
    switch (this) {
      case FanMode.auto:
        return 'Adapts fan speed to PM2.5 in real time';
      case FanMode.low:
        return 'Quiet operation, lower airflow';
      case FanMode.medium:
        return 'Balanced protection and battery life';
      case FanMode.high:
        return 'Maximum protection, shorter battery life';
    }
  }

  /// Base fan speed factor (0–1) for this mode
  double get baseSpeed {
    switch (this) {
      case FanMode.auto:
        return 0.62;
      case FanMode.low:
        return 0.30;
      case FanMode.medium:
        return 0.60;
      case FanMode.high:
        return 1.0;
    }
  }

  int get bars {
    switch (this) {
      case FanMode.auto:
        return 2;
      case FanMode.low:
        return 1;
      case FanMode.medium:
        return 2;
      case FanMode.high:
        return 3;
    }
  }
}

/// Immutable snapshot of helmet state.
class HelmetState {
  final String name;
  final String serial;
  final String firmware;
  final bool isConnected;
  final double batteryPercent;
  final bool isCharging;
  final double filterHealthPercent;
  final FanMode fanMode;
  final double fanSpeedFactor; // 0–1
  final bool isPurifying;
  final DateTime lastSyncTime;

  const HelmetState({
    required this.name,
    required this.serial,
    required this.firmware,
    required this.isConnected,
    required this.batteryPercent,
    required this.isCharging,
    required this.filterHealthPercent,
    required this.fanMode,
    required this.fanSpeedFactor,
    required this.isPurifying,
    required this.lastSyncTime,
  });

  HelmetState copyWith({
    String? name,
    String? serial,
    String? firmware,
    bool? isConnected,
    double? batteryPercent,
    bool? isCharging,
    double? filterHealthPercent,
    FanMode? fanMode,
    double? fanSpeedFactor,
    bool? isPurifying,
    DateTime? lastSyncTime,
  }) {
    return HelmetState(
      name: name ?? this.name,
      serial: serial ?? this.serial,
      firmware: firmware ?? this.firmware,
      isConnected: isConnected ?? this.isConnected,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      isCharging: isCharging ?? this.isCharging,
      filterHealthPercent: filterHealthPercent ?? this.filterHealthPercent,
      fanMode: fanMode ?? this.fanMode,
      fanSpeedFactor: fanSpeedFactor ?? this.fanSpeedFactor,
      isPurifying: isPurifying ?? this.isPurifying,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }
}
