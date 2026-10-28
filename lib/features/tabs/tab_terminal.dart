import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../bluetooth/bluetooth_monitor_screen.dart';

class TabTerminal extends ConsumerWidget {
  const TabTerminal({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Direct embed of the Bluetooth Live Terminal Screen
    return const BluetoothMonitorScreen();
  }
}
