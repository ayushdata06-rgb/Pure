import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/colors.dart';
import '../../providers/bluetooth_provider.dart';

class TabSensors extends ConsumerWidget {
  const TabSensors({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bme = ref.watch(latestBme680Provider);
    final history = ref.watch(bme680HistoryProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Environment & Sensors',
            style: GoogleFonts.sora(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
            ),
          ),
          const Gap(4),
          Text(
            'Tab 2 · Ready to redesign',
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
                Text(
                  'BME680 Sensor Metrics (${history.length} logged points)',
                  style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const Gap(12),
                if (bme != null) ...[
                  Text('Temperature: ${bme.temperature.toStringAsFixed(2)} °C'),
                  Text('Humidity: ${bme.humidity.toStringAsFixed(2)} %'),
                  Text('Pressure: ${bme.pressure.toStringAsFixed(2)} hPa'),
                  Text('Gas Resistance: ${bme.gasResistance.toStringAsFixed(2)} kΩ'),
                  Text('Est. Altitude: ${bme.altitude.toStringAsFixed(2)} m'),
                ] else
                  const Text('No sensor data received yet.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
