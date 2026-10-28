import 'dart:convert';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/bluetooth/bluetooth_models.dart';
import '../core/bluetooth/bluetooth_service.dart';
import '../core/firebase/firebase_service.dart';
import '../data/models/bme680_reading.dart';
import 'outdoor_provider.dart';
import 'ride_session_provider.dart';

final bluetoothServiceProvider = Provider<BluetoothSerialService>((ref) {
  return BluetoothSerialService.instance;
});

final bluetoothStateStreamProvider = StreamProvider<BleConnectionState>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  return service.stateStream;
});

final bondedDevicesFutureProvider =
    FutureProvider.autoDispose<List<BluetoothDevice>>((ref) async {
  final service = ref.watch(bluetoothServiceProvider);
  return await service.getBondedDevices();
});

final discoveredDevicesStreamProvider =
    StreamProvider<List<BluetoothDevice>>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  return service.devicesStream;
});

final latestBme680Provider = StateProvider<Bme680Reading?>((ref) => null);

/// Accumulated real BME680 telemetry history (last 100 points)
final bme680HistoryProvider =
    StateNotifierProvider<Bme680HistoryNotifier, List<Bme680Reading>>((ref) {
  return Bme680HistoryNotifier();
});

class Bme680HistoryNotifier extends StateNotifier<List<Bme680Reading>> {
  Bme680HistoryNotifier() : super([]);

  static const _maxPoints = 100;

  void addReading(Bme680Reading reading) {
    final newList = [...state, reading];
    if (newList.length > _maxPoints) {
      state = newList.sublist(newList.length - _maxPoints);
    } else {
      state = newList;
    }
  }

  void clear() {
    state = [];
  }
}

final bluetoothLogsProvider =
    StateNotifierProvider<BluetoothLogsNotifier, List<BluetoothLogEntry>>((ref) {
  final service = ref.watch(bluetoothServiceProvider);
  final notifier = BluetoothLogsNotifier(service);

  service.logStream.listen((entry) {
    notifier.addEntry(entry);

    // If incoming packet, log raw telemetry to Firebase
    if (!entry.isOutgoing) {
      FirebaseService.instance.logRawTelemetry(
        rawData: entry.text,
        deviceName: service.connectedDevice?.name ?? 'ESP32_BME680_Full',
        deviceAddress: service.connectedDevice?.address ?? 'F4:2D:C9:89:D7:02',
      );
    }
  });

  // Listen for parsed lines to update real BME680 state
  service.lineStream.listen((line) {
    _tryParseAndInjectLine(ref, line);
  });

  return notifier;
});

class BluetoothLogsNotifier extends StateNotifier<List<BluetoothLogEntry>> {
  final BluetoothSerialService _service;
  BluetoothLogsNotifier(this._service) : super([]) {
    state = List.from(_service.logs);
  }

  void addEntry(BluetoothLogEntry entry) {
    state = [...state, entry];
    if (state.length > 500) {
      state = state.sublist(state.length - 500);
    }
  }

  void clear() {
    _service.clearLogs();
    state = [];
  }
}

final autoScrollProvider = StateProvider<bool>((ref) => true);
final hexViewProvider = StateProvider<bool>((ref) => false);
final isLiveEsp32ActiveProvider = StateProvider<bool>((ref) => false);
final fanStateProvider = StateProvider<bool>((ref) => false);
final lastFanCommandProvider = StateProvider<String?>((ref) => null);

class _Bme680Accumulator {
  double? temp;
  double? humidity;
  double? pressure;
  double? gasRes;
  double? altitude;

  bool feedLine(String line) {
    final lower = line.toLowerCase();
    final colonIdx = line.indexOf(':');
    if (colonIdx != -1) {
      final valuePart = line.substring(colonIdx + 1);
      final numMatch = RegExp(r'[-+]?\d*\.?\d+').firstMatch(valuePart);
      final val = numMatch != null ? double.tryParse(numMatch.group(0)!) : null;

      if (val != null) {
        if (lower.contains('temperature') || lower.contains('temp')) {
          temp = val;
        } else if (lower.contains('humidity') || lower.contains('humid')) {
          humidity = val;
        } else if (lower.contains('pressure') || lower.contains('press')) {
          pressure = val;
        } else if (lower.contains('gas res') || lower.contains('gas')) {
          gasRes = val;
        } else if (lower.contains('altitude') || lower.contains('alt')) {
          altitude = val;
        }
      }
    }

    return temp != null &&
        humidity != null &&
        pressure != null &&
        gasRes != null &&
        altitude != null;
  }

  Bme680Reading toReading() {
    return Bme680Reading(
      timestamp: DateTime.now(),
      temperature: temp ?? 25.0,
      humidity: humidity ?? 50.0,
      pressure: pressure ?? 1013.25,
      gasResistance: gasRes ?? 50.0,
      altitude: altitude ?? 0.0,
    );
  }

  void reset() {
    temp = null;
    humidity = null;
    pressure = null;
    gasRes = null;
    altitude = null;
  }
}

final _bmeAccumulator = _Bme680Accumulator();

/// Parse incoming serial lines for BME680 sensor blocks or JSON telemetry
void _tryParseAndInjectLine(Ref ref, String line) {
  try {
    // 1. Check for Bosch BME680 serial block
    final isComplete = _bmeAccumulator.feedLine(line);
    if (isComplete || line.contains('========================')) {
      if (_bmeAccumulator.temp != null && _bmeAccumulator.humidity != null) {
        final bmeReading = _bmeAccumulator.toReading();
        _bmeAccumulator.reset();

        ref.read(latestBme680Provider.notifier).state = bmeReading;
        ref.read(bme680HistoryProvider.notifier).addReading(bmeReading);
        ref.read(isLiveEsp32ActiveProvider.notifier).state = true;

        FirebaseService.instance.saveBme680Telemetry(bmeReading);
        return;
      }
    }

    // 2. Check for power/fan status response from ESP32: STATUS: ON, STATUS: OFF, ON, OFF, etc.
    final lower = line.toLowerCase();
    if (lower == 'status: on' || lower == 'status:on' || lower == 'on' || lower.contains('"fan":"on"') || lower.contains('"fan": "on"') || lower.contains('fan:1')) {
      ref.read(fanStateProvider.notifier).state = true;
    } else if (lower == 'status: off' || lower == 'status:off' || lower == 'off' || lower.contains('"fan":"off"') || lower.contains('"fan": "off"') || lower.contains('fan:0')) {
      ref.read(fanStateProvider.notifier).state = false;
    }

    // 3. Fallback JSON support if firmware transmits JSON: {"temp": 29.2, "humidity": 66.0, ...}
    if (line.trim().startsWith('{') && line.trim().endsWith('}')) {
      final json = jsonDecode(line) as Map<String, dynamic>;
      if (json.containsKey('temperature') || json.containsKey('temp')) {
        final bmeReading = Bme680Reading(
          timestamp: DateTime.now(),
          temperature: (json['temperature'] ?? json['temp'] ?? 0.0).toDouble(),
          humidity: (json['humidity'] ?? json['hum'] ?? 0.0).toDouble(),
          pressure: (json['pressure'] ?? json['press'] ?? 0.0).toDouble(),
          gasResistance: (json['gas_res'] ?? json['gas'] ?? 0.0).toDouble(),
          altitude: (json['altitude'] ?? json['alt'] ?? 0.0).toDouble(),
        );

        ref.read(latestBme680Provider.notifier).state = bmeReading;
        ref.read(bme680HistoryProvider.notifier).addReading(bmeReading);
        ref.read(isLiveEsp32ActiveProvider.notifier).state = true;
        FirebaseService.instance.saveBme680Telemetry(bmeReading);

        // Record periodic snapshot into active ride session if running
        final sessionState = ref.read(rideSessionProvider);
        if (sessionState.isRideActive) {
          final outdoor = ref.read(outdoorDataProvider);
          ref.read(rideSessionProvider.notifier).recordSnapshot(
                insideAqi: bmeReading.calculatedAqi,
                outsideAqi: outdoor.aqi,
                temperature: bmeReading.temperature,
                humidity: bmeReading.humidity,
              );
        }
      }
    }
  } catch (_) {
    // Custom/unstructured lines are still preserved in bluetoothLogsProvider
  }
}

/// Send Fan/Power switch command via ESP32 Bluetooth Classic (ON\n / OFF\n)
Future<bool> sendFanCommand(WidgetRef ref, bool enable) async {
  final service = ref.read(bluetoothServiceProvider);
  final cmd = enable ? 'ON\n' : 'OFF\n';
  ref.read(fanStateProvider.notifier).state = enable;
  final now = DateTime.now();
  final timeStr = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  ref.read(lastFanCommandProvider.notifier).state = '${enable ? "ON" : "OFF"} at $timeStr';

  // Manage ride session lifecycle when fan state changes
  if (enable) {
    final bme = ref.read(latestBme680Provider);
    final outdoor = ref.read(outdoorDataProvider);
    ref.read(rideSessionProvider.notifier).startSession(
          insideAqi: bme?.calculatedAqi ?? 0,
          outsideAqi: outdoor.aqi,
          temperature: bme?.temperature ?? 0.0,
          humidity: bme?.humidity ?? 0.0,
        );
  } else {
    ref.read(rideSessionProvider.notifier).endSession();
  }

  return await service.sendString(cmd);
}



