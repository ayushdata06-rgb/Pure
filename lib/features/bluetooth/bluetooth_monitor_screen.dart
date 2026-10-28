import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/bluetooth/bluetooth_models.dart';
import '../../core/bluetooth/bluetooth_service.dart';
import '../../core/theme/colors.dart';
import '../../core/theme/typography.dart';
import '../../providers/bluetooth_provider.dart';

class BluetoothMonitorScreen extends ConsumerStatefulWidget {
  const BluetoothMonitorScreen({super.key});

  @override
  ConsumerState<BluetoothMonitorScreen> createState() => _BluetoothMonitorScreenState();
}

class _BluetoothMonitorScreenState extends ConsumerState<BluetoothMonitorScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _commandController = TextEditingController();

  @override
  void dispose() {
    _scrollController.dispose();
    _commandController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 150),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = ref.watch(bluetoothServiceProvider);
    final logs = ref.watch(bluetoothLogsProvider);
    final autoScroll = ref.watch(autoScrollProvider);
    final hexView = ref.watch(hexViewProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Trigger auto-scroll when new log arrives if enabled
    ref.listen<List<BluetoothLogEntry>>(bluetoothLogsProvider, (_, next) {
      if (autoScroll && next.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
      }
    });

    final totalBytes = logs.fold<int>(0, (acc, entry) => acc + entry.byteCount);
    final statusColor = switch (service.state) {
      BleConnectionState.connected => PureColors.aqiGood,
      BleConnectionState.connecting => PureColors.aqiModerate,
      BleConnectionState.scanning => PureColors.secondaryBlue,
      BleConnectionState.error => PureColors.aqiVeryPoor,
      BleConnectionState.disconnected => PureColors.textMuted,
    };

    final statusText = switch (service.state) {
      BleConnectionState.connected => 'Connected to ${service.connectedDevice?.name ?? 'ESP32'}',
      BleConnectionState.connecting => 'Connecting to ESP32...',
      BleConnectionState.scanning => 'Scanning for Bluetooth devices...',
      BleConnectionState.error => 'Error: ${service.errorMessage}',
      BleConnectionState.disconnected => 'Disconnected (ESP32 Bluetooth Serial)',
    };

    return Scaffold(
      backgroundColor: isDark ? PureColors.darkBackground : PureColors.lightBackground,
      appBar: AppBar(
        backgroundColor: isDark ? PureColors.darkSurface : PureColors.lightSurface,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ESP32 Serial Monitor',
              style: GoogleFonts.sora(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                ),
                const Gap(6),
                Expanded(
                  child: Text(
                    statusText,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Hex / ASCII toggle
          IconButton(
            tooltip: hexView ? 'Switch to ASCII Text' : 'Switch to HEX Bytes',
            icon: Icon(
              hexView ? Icons.data_object_rounded : Icons.code_rounded,
              color: hexView ? PureColors.primaryTeal : PureColors.textSecondary,
            ),
            onPressed: () {
              ref.read(hexViewProvider.notifier).state = !hexView;
            },
          ),
          // Copy all
          IconButton(
            tooltip: 'Copy all received data',
            icon: const Icon(Icons.copy_all_rounded),
            onPressed: logs.isEmpty ? null : () => _copyLogsToClipboard(logs),
          ),
          // Clear
          IconButton(
            tooltip: 'Clear terminal',
            icon: const Icon(Icons.delete_sweep_rounded),
            onPressed: logs.isEmpty ? null : () => ref.read(bluetoothLogsProvider.notifier).clear(),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Connection Bar & Controls ─────────────────────
          _buildConnectionPanel(context, service, isDark),

          // ── Payload Analyzer Strip ────────────────────────
          _buildPayloadAnalyzer(logs, totalBytes, isDark),

          // ── Live Terminal Console ─────────────────────────
          Expanded(
            child: _buildTerminalConsole(logs, autoScroll, hexView, isDark),
          ),

          // ── Bottom Command Sender ─────────────────────────
          _buildCommandBar(service, isDark),
        ],
      ),
    );
  }

  Widget _buildConnectionPanel(
      BuildContext context, BluetoothSerialService service, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? PureColors.darkSurface : PureColors.lightSurface,
        border: Border(
          bottom: BorderSide(
            color: isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder,
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.isConnected
                      ? (service.connectedDevice?.name ?? 'ESP32 Device')
                      : 'No Device Connected',
                  style: GoogleFonts.sora(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                  ),
                ),
                Text(
                  service.isConnected
                      ? 'MAC: ${service.connectedDevice?.address}'
                      : 'Pair ESP32 in phone Bluetooth settings, then select it below',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                  ),
                ),
              ],
            ),
          ),
          if (service.isConnected)
            FilledButton.tonalIcon(
              style: FilledButton.styleFrom(
                backgroundColor: PureColors.aqiVeryPoor.withOpacity(0.15),
                foregroundColor: PureColors.aqiVeryPoor,
              ),
              icon: const Icon(Icons.bluetooth_disabled_rounded, size: 16),
              label: const Text('Disconnect'),
              onPressed: () => service.disconnect(),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: PureColors.primaryTeal,
                foregroundColor: Colors.black,
              ),
              icon: const Icon(Icons.bluetooth_searching_rounded, size: 16),
              label: const Text('Pick ESP32'),
              onPressed: () => _showDevicePickerSheet(context),
            ),
        ],
      ),
    );
  }

  Widget _buildPayloadAnalyzer(List<BluetoothLogEntry> logs, int totalBytes, bool isDark) {
    final incomingLogs = logs.where((e) => !e.isOutgoing).toList();
    final lastPacket = incomingLogs.isNotEmpty ? incomingLogs.last.text.trim() : null;

    String detectedType = 'Waiting for stream...';
    Color tagColor = PureColors.textMuted;

    final hasBme680 = incomingLogs.any((e) => e.text.contains('BME680') || e.text.contains('Gas Res'));
    final bme = ref.watch(latestBme680Provider);

    if (bme != null || hasBme680) {
      detectedType = bme != null
          ? 'BME680: ${bme.temperature.toStringAsFixed(1)}°C · ${bme.humidity.toStringAsFixed(0)}% · ${bme.gasResistance.toStringAsFixed(1)}kΩ'
          : 'Bosch BME680 Sensor Block Detected';
      tagColor = PureColors.primaryTeal;
    } else if (lastPacket != null) {
      if (lastPacket.startsWith('{') && lastPacket.endsWith('}')) {
        detectedType = 'JSON Object Payload Detected';
        tagColor = PureColors.primaryTeal;
      } else if (lastPacket.contains(',') && double.tryParse(lastPacket.split(',').first.trim()) != null) {
        detectedType = 'CSV / Comma Separated Telemetry';
        tagColor = PureColors.secondaryBlue;
      } else if (double.tryParse(lastPacket) != null) {
        detectedType = 'Single Numeric Sensor Value';
        tagColor = PureColors.aqiModerate;
      } else {
        detectedType = 'Plaintext / Custom Stream';
        tagColor = PureColors.aqiGood;
      }
    }


    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? PureColors.darkSurfaceElevated : PureColors.lightSurfaceElevated,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: tagColor.withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: tagColor.withOpacity(0.3)),
            ),
            child: Text(
              detectedType,
              style: GoogleFonts.jetBrainsMono(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: tagColor,
              ),
            ),
          ),
          const Spacer(),
          Text(
            '${logs.length} pkts · ${_formatBytes(totalBytes)}',
            style: GoogleFonts.jetBrainsMono(
              fontSize: 11,
              color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTerminalConsole(
      List<BluetoothLogEntry> logs, bool autoScroll, bool hexView, bool isDark) {
    if (logs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.terminal_rounded,
                size: 56,
                color: PureColors.primaryTeal.withOpacity(0.4),
              ),
              const Gap(16),
              Text(
                'Live Terminal Ready',
                style: PureTypography.sectionTitle(
                  isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                ),
              ),
              const Gap(8),
              Text(
                'Connect to your ESP32 Bluetooth to inspect incoming raw sensor telemetry in real time.',
                textAlign: TextAlign.center,
                style: PureTypography.body(
                  isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: isDark ? const Color(0xFF070B0E) : const Color(0xFF1E242B),
      child: Stack(
        children: [
          ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            itemCount: logs.length,
            itemBuilder: (context, index) {
              final entry = logs[index];
              final timeStr =
                  '${entry.timestamp.hour.toString().padLeft(2, '0')}:'
                  '${entry.timestamp.minute.toString().padLeft(2, '0')}:'
                  '${entry.timestamp.second.toString().padLeft(2, '0')}.'
                  '${entry.timestamp.millisecond.toString().padLeft(3, '0')}';

              final textColor = entry.isOutgoing
                  ? const Color(0xFFFFB454) // Outgoing (Orange)
                  : const Color(0xFF39E8C7); // Incoming (Teal/Cyan)

              final displayContent = hexView ? entry.hexString : entry.text;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '[$timeStr] ',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        color: const Color(0xFF5A6B78),
                      ),
                    ),
                    Text(
                      entry.isOutgoing ? 'TX > ' : 'RX < ',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: entry.isOutgoing ? Colors.orangeAccent : PureColors.primaryTeal,
                      ),
                    ),
                    Expanded(
                      child: SelectableText(
                        displayContent,
                        style: GoogleFonts.jetBrainsMono(
                          fontSize: 12,
                          color: textColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                    const Gap(6),
                    Text(
                      '${entry.byteCount}B',
                      style: GoogleFonts.jetBrainsMono(
                        fontSize: 9,
                        color: const Color(0xFF4A5568),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),

          // Auto-scroll toggle badge
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.small(
              backgroundColor: autoScroll
                  ? PureColors.primaryTeal.withOpacity(0.9)
                  : (isDark ? PureColors.darkSurfaceElevated : Colors.white),
              foregroundColor: autoScroll ? Colors.black : PureColors.textSecondary,
              tooltip: autoScroll ? 'Auto-scroll: ON' : 'Auto-scroll: PAUSED',
              onPressed: () {
                final next = !autoScroll;
                ref.read(autoScrollProvider.notifier).state = next;
                if (next) _scrollToBottom();
              },
              child: Icon(
                autoScroll ? Icons.arrow_downward_rounded : Icons.pause_rounded,
                size: 18,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommandBar(BluetoothSerialService service, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? PureColors.darkSurface : PureColors.lightSurface,
        border: Border(
          top: BorderSide(
            color: isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder,
          ),
        ),
      ),
      child: Column(
        children: [
          // Quick Command Presets
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildQuickChip('STATUS', service),
                const Gap(8),
                _buildQuickChip('READ', service),
                const Gap(8),
                _buildQuickChip('FAN:1', service),
                const Gap(8),
                _buildQuickChip('FAN:0', service),
                const Gap(8),
                _buildQuickChip('PING', service),
              ],
            ),
          ),
          const Gap(8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _commandController,
                  style: GoogleFonts.jetBrainsMono(
                    fontSize: 13,
                    color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type command or test payload to send...',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 12,
                      color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                    ),
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder,
                      ),
                    ),
                  ),
                  onSubmitted: (val) => _sendCommand(val, service),
                ),
              ),
              const Gap(8),
              IconButton.filled(
                style: IconButton.styleFrom(
                  backgroundColor: PureColors.primaryTeal,
                  foregroundColor: Colors.black,
                ),
                icon: const Icon(Icons.send_rounded, size: 18),
                onPressed: () => _sendCommand(_commandController.text, service),
              ),

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChip(String label, BluetoothSerialService service) {
    return ActionChip(
      label: Text(label, style: GoogleFonts.jetBrainsMono(fontSize: 11)),
      padding: EdgeInsets.zero,
      visualDensity: VisualDensity.compact,
      onPressed: () => _sendCommand(label, service),
    );
  }

  void _sendCommand(String text, BluetoothSerialService service) {
    if (text.trim().isEmpty) return;
    if (!service.isConnected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please connect to ESP32 before sending commands.')),
      );
      return;
    }
    // Append newline automatically if not already present
    final payload = text.endsWith('\n') ? text : '$text\n';
    service.sendString(payload);
    _commandController.clear();
  }

  void _copyLogsToClipboard(List<BluetoothLogEntry> logs) {
    final hexView = ref.read(hexViewProvider);
    final buffer = StringBuffer();
    for (final entry in logs) {
      final direction = entry.isOutgoing ? 'TX' : 'RX';
      final content = hexView ? entry.hexString : entry.text;
      buffer.writeln('[${entry.timestamp.toIso8601String()}] $direction: $content');
    }
    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Copied ${logs.length} packet logs to clipboard!')),
    );
  }

  void _showDevicePickerSheet(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final service = ref.read(bluetoothServiceProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? PureColors.darkSurfaceElevated : PureColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Consumer(
        builder: (context, ref, _) {
          final bondedAsync = ref.watch(bondedDevicesFutureProvider);

          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Select ESP32 Device',
                      style: PureTypography.sectionTitle(
                        isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh_rounded),
                      onPressed: () => ref.refresh(bondedDevicesFutureProvider),
                    ),
                  ],
                ),
                Text(
                  'Make sure your ESP32 Bluetooth is turned on and paired in Android Bluetooth settings.',
                  style: PureTypography.body(
                    isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                  ),
                ),
                const Gap(16),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 280),
                  child: bondedAsync.when(
                    data: (devices) {
                      if (devices.isEmpty) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No paired devices found.\nPlease open Android Settings > Bluetooth and pair your ESP32 first.',
                              textAlign: TextAlign.center,
                              style: PureTypography.body(
                                isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        itemCount: devices.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final device = devices[index];
                          final isEsp = (device.name ?? '').toLowerCase().contains('esp') ||
                              (device.name ?? '').toLowerCase().contains('helmet') ||
                              (device.name ?? '').toLowerCase().contains('pure');

                          return ListTile(
                            leading: Icon(
                              Icons.bluetooth_connected_rounded,
                              color: isEsp ? PureColors.primaryTeal : PureColors.textSecondary,
                            ),
                            title: Text(
                              device.name ?? 'Unknown Device',
                              style: TextStyle(
                                fontWeight: isEsp ? FontWeight.bold : FontWeight.normal,
                              ),
                            ),
                            subtitle: Text(
                              '${device.address} ${isEsp ? "· (ESP32)" : ""}',
                              style: GoogleFonts.jetBrainsMono(fontSize: 11),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isEsp ? PureColors.primaryTeal : null,
                                foregroundColor: isEsp ? Colors.black : null,
                              ),
                              child: const Text('Connect'),
                              onPressed: () {
                                Navigator.pop(ctx);
                                service.connect(device);
                              },
                            ),
                          );
                        },
                      );
                    },
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    error: (err, _) => Center(
                      child: Text('Error loading devices: $err'),
                    ),
                  ),
                ),
                const Gap(16),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }
}
