import 'dart:typed_data';

enum BleConnectionState {
  disconnected,
  scanning,
  connecting,
  connected,
  error,
}

class BluetoothLogEntry {
  final DateTime timestamp;
  final String text;
  final Uint8List rawBytes;
  final bool isOutgoing;

  BluetoothLogEntry({
    required this.timestamp,
    required this.text,
    required this.rawBytes,
    this.isOutgoing = false,
  });

  int get byteCount => rawBytes.length;

  String get hexString =>
      rawBytes.map((b) => b.toRadixString(16).padLeft(2, '0').toUpperCase()).join(' ');
}
