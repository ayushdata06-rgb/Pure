import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:permission_handler/permission_handler.dart';
import 'bluetooth_models.dart';

class BluetoothSerialService {
  BluetoothSerialService._();
  static final BluetoothSerialService instance = BluetoothSerialService._();

  BluetoothConnection? _connection;
  BluetoothDevice? _connectedDevice;
  BleConnectionState _state = BleConnectionState.disconnected;
  String _errorMessage = '';

  final _stateController = StreamController<BleConnectionState>.broadcast();
  final _logController = StreamController<BluetoothLogEntry>.broadcast();
  final _lineController = StreamController<String>.broadcast();
  final _devicesController = StreamController<List<BluetoothDevice>>.broadcast();

  final List<BluetoothLogEntry> _logs = [];
  final List<BluetoothDevice> _devices = [];
  String _incomingBuffer = '';
  StreamSubscription<BluetoothDiscoveryResult>? _discoverySubscription;

  // Getters
  BleConnectionState get state => _state;
  BluetoothDevice? get connectedDevice => _connectedDevice;
  bool get isConnected => _connection?.isConnected ?? false;
  String get errorMessage => _errorMessage;
  List<BluetoothLogEntry> get logs => List.unmodifiable(_logs);
  List<BluetoothDevice> get devices => List.unmodifiable(_devices);

  Stream<BleConnectionState> get stateStream => _stateController.stream;
  Stream<BluetoothLogEntry> get logStream => _logController.stream;
  Stream<String> get lineStream => _lineController.stream;
  Stream<List<BluetoothDevice>> get devicesStream => _devicesController.stream;

  void _setState(BleConnectionState newState, {String error = ''}) {
    _state = newState;
    _errorMessage = error;
    _stateController.add(newState);
  }

  /// Request all required runtime permissions for Android 12+ and older
  Future<bool> requestPermissions() async {
    if (!Platform.isAndroid) return true;

    try {
      final statuses = await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location,
      ].request();

      final connectGranted = statuses[Permission.bluetoothConnect]?.isGranted ?? true;
      final scanGranted = statuses[Permission.bluetoothScan]?.isGranted ?? true;
      final locationGranted = statuses[Permission.location]?.isGranted ?? true;

      return (connectGranted && scanGranted) || locationGranted;
    } catch (e) {
      debugPrint('[BluetoothService] Permission request error: $e');
      return false;
    }
  }

  /// Load paired/bonded devices from Android Bluetooth settings
  Future<List<BluetoothDevice>> getBondedDevices() async {
    try {
      await requestPermissions();
      final bonded = await FlutterBluetoothSerial.instance.getBondedDevices();
      _devices.clear();
      _devices.addAll(bonded);
      _devicesController.add(List.unmodifiable(_devices));
      return _devices;
    } catch (e) {
      debugPrint('[BluetoothService] Failed to get bonded devices: $e');
      _errorMessage = 'Could not load bonded devices: $e';
      return [];
    }
  }

  /// Start scanning for nearby discoverable Bluetooth devices
  Future<void> startDiscovery() async {
    try {
      await requestPermissions();
      _setState(BleConnectionState.scanning);

      _discoverySubscription?.cancel();
      _discoverySubscription =
          FlutterBluetoothSerial.instance.startDiscovery().listen((result) {
        final existingIndex =
            _devices.indexWhere((d) => d.address == result.device.address);
        if (existingIndex >= 0) {
          _devices[existingIndex] = result.device;
        } else {
          _devices.add(result.device);
        }
        _devicesController.add(List.unmodifiable(_devices));
      });

      _discoverySubscription?.onDone(() {
        if (_state == BleConnectionState.scanning) {
          _setState(BleConnectionState.disconnected);
        }
      });
    } catch (e) {
      debugPrint('[BluetoothService] Discovery error: $e');
      _setState(BleConnectionState.error, error: 'Scan error: $e');
    }
  }

  /// Stop scanning
  Future<void> stopDiscovery() async {
    await _discoverySubscription?.cancel();
    _discoverySubscription = null;
    if (_state == BleConnectionState.scanning) {
      _setState(BleConnectionState.disconnected);
    }
  }

  /// Connect to ESP32 by device address or BluetoothDevice
  Future<bool> connect(BluetoothDevice device) async {
    await stopDiscovery();
    await disconnect();

    _setState(BleConnectionState.connecting);
    _connectedDevice = device;

    try {
      _connection = await BluetoothConnection.toAddress(device.address);
      _setState(BleConnectionState.connected);

      _connection!.input?.listen(
        _onDataReceived,
        onDone: () {
          debugPrint('[BluetoothService] Disconnected by remote device');
          _onDisconnected();
        },
        onError: (error) {
          debugPrint('[BluetoothService] Connection stream error: $error');
          _setState(BleConnectionState.error, error: error.toString());
          _onDisconnected();
        },
        cancelOnError: true,
      );

      return true;
    } catch (e) {
      debugPrint('[BluetoothService] Failed to connect: $e');
      _setState(BleConnectionState.error, error: 'Connection failed: $e');
      _onDisconnected();
      return false;
    }
  }

  void _onDataReceived(Uint8List data) {
    final text = utf8.decode(data, allowMalformed: true);
    final entry = BluetoothLogEntry(
      timestamp: DateTime.now(),
      text: text,
      rawBytes: data,
      isOutgoing: false,
    );

    _logs.add(entry);
    // Keep last 500 entries to prevent memory pressure
    if (_logs.length > 500) {
      _logs.removeRange(0, _logs.length - 500);
    }
    _logController.add(entry);

    // Also buffer line by line (split on \n or \r\n)
    _incomingBuffer += text;
    while (_incomingBuffer.contains('\n')) {
      final newlineIdx = _incomingBuffer.indexOf('\n');
      final line = _incomingBuffer.substring(0, newlineIdx).replaceAll('\r', '').trim();
      _incomingBuffer = _incomingBuffer.substring(newlineIdx + 1);
      if (line.isNotEmpty) {
        _lineController.add(line);
      }
    }
  }

  /// Send string/command to ESP32 over serial RFCOMM
  Future<bool> sendString(String data) async {
    if (!isConnected || _connection == null) {
      return false;
    }

    try {
      final bytes = Uint8List.fromList(utf8.encode(data));
      _connection!.output.add(bytes);
      await _connection!.output.allSent;

      final entry = BluetoothLogEntry(
        timestamp: DateTime.now(),
        text: data,
        rawBytes: bytes,
        isOutgoing: true,
      );
      _logs.add(entry);
      _logController.add(entry);
      return true;
    } catch (e) {
      debugPrint('[BluetoothService] Error sending data: $e');
      return false;
    }
  }

  /// Disconnect current connection
  Future<void> disconnect() async {
    try {
      await _connection?.close();
      _connection?.dispose();
    } catch (e) {
      debugPrint('[BluetoothService] Error during disconnect: $e');
    } finally {
      _connection = null;
      _onDisconnected();
    }
  }

  void _onDisconnected() {
    _connectedDevice = null;
    _setState(BleConnectionState.disconnected);
  }

  /// Clear in-memory log buffer
  void clearLogs() {
    _logs.clear();
    _incomingBuffer = '';
    _stateController.add(_state);
  }

  void dispose() {
    _discoverySubscription?.cancel();
    _connection?.dispose();
    _stateController.close();
    _logController.close();
    _lineController.close();
    _devicesController.close();
  }
}
