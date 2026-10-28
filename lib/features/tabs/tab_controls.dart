import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/colors.dart';
import '../../providers/bluetooth_provider.dart';

class TabControls extends ConsumerStatefulWidget {
  const TabControls({super.key});

  @override
  ConsumerState<TabControls> createState() => _TabControlsState();
}

class _TabControlsState extends ConsumerState<TabControls> {
  @override
  Widget build(BuildContext context) {
    final service = ref.watch(bluetoothServiceProvider);
    final isConnected = service.isConnected;
    final isFanOn = ref.watch(fanStateProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Helmet Controls',
            style: GoogleFonts.sora(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
            ),
          ),
          const Gap(4),
          Text(
            'Tab 3 · Ready to redesign',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
            ),
          ),
          const Gap(24),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: isDark ? PureColors.darkSurface : PureColors.lightSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Purification Fan',
                      style: GoogleFonts.sora(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    Switch(
                      value: isFanOn,
                      activeColor: PureColors.primaryTeal,
                      onChanged: isConnected
                          ? (val) => sendFanCommand(ref, val)
                          : null,
                    ),
                  ],
                ),
                const Gap(8),
                Text(
                  isConnected
                      ? (isFanOn ? 'Circuit state: STATUS: ON (Signal ON)' : 'Circuit state: STATUS: OFF (Signal OFF)')
                      : 'Connect ESP32 to control the helmet fan',
                  style: GoogleFonts.inter(fontSize: 12, color: PureColors.textMuted),
                ),
                const Divider(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isConnected ? () => service.sendString('PING\n') : null,
                        child: const Text('Ping ESP32'),
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isConnected ? () => service.sendString('STATUS\n') : null,
                        child: const Text('Query Status'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
