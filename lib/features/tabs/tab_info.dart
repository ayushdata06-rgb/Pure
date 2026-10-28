import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/colors.dart';
import '../../data/models/bme680_reading.dart';
import '../../providers/bluetooth_provider.dart';
import '../../widgets/math_info_dialog.dart';

class TabInfo extends ConsumerWidget {
  const TabInfo({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bme = ref.watch(latestBme680Provider);
    final btService = ref.watch(bluetoothServiceProvider);
    final isConnected = btService.isConnected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final advisory = bme?.fanAdvisory;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ==========================================
          // 1. SCENARIO INTELLIGENCE: AUTO-FAN ADVISORY
          // ==========================================
          _buildFanAdvisoryCard(
            isDark: isDark,
            advisory: advisory,
            isConnected: isConnected,
          ),

          const Gap(16),

          // ==========================================
          // 2. VISOR FOG RISK (DEW POINT ANALYSIS)
          // ==========================================
          _buildVisorFogCard(
            context: context,
            isDark: isDark,
            bme: bme,
            isConnected: isConnected,
          ),

          const Gap(16),

          // ==========================================
          // 3. HEAT INDEX & EXHALED BREATH (SIDE-BY-SIDE)
          // ==========================================
          Row(
            children: [
              // Left: Feels Like Heat Index
              Expanded(
                child: _buildHeatIndexCard(
                  context: context,
                  isDark: isDark,
                  bme: bme,
                ),
              ),
              const Gap(12),
              // Right: Stale Breath / Exhaled Air
              Expanded(
                child: _buildStaleAirCard(
                  context: context,
                  isDark: isDark,
                  bme: bme,
                ),
              ),
            ],
          ),

          const Gap(16),

          // ==========================================
          // 4. ATMOSPHERIC & ALTITUDE DIAGNOSTICS
          // ==========================================
          _buildAtmosphericCard(
            context: context,
            isDark: isDark,
            bme: bme,
            isConnected: isConnected,
          ),

          const Gap(14),
        ],
      ),
    );
  }

  /// 1. Scenario Intelligence & Fan Advisory Card (Info Only)
  Widget _buildFanAdvisoryCard({
    required bool isDark,
    required FanAdvisory? advisory,
    required bool isConnected,
  }) {
    final cardBg = isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final borderCol = isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder;
    final activeColor = advisory?.color ?? PureColors.primaryTeal;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isConnected && advisory != null
              ? activeColor.withOpacity(0.4)
              : borderCol,
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: (isConnected && advisory != null ? activeColor : Colors.black)
                .withOpacity(isDark ? 0.15 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isConnected && advisory != null ? activeColor : Colors.grey)
                      .withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.psychology_rounded,
                  size: 20,
                  color: isConnected && advisory != null ? activeColor : Colors.grey,
                ),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SMART FAN ADVISORY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                      ),
                    ),
                    Text(
                      isConnected && advisory != null
                          ? advisory.title
                          : 'Awaiting ESP32 Live Stream',
                      style: GoogleFonts.sora(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isConnected && advisory != null
                            ? activeColor
                            : (isDark ? PureColors.textPrimary : PureColors.lightTextPrimary),
                      ),
                    ),
                  ],
                ),
              ),
              if (isConnected && advisory != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: activeColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: activeColor.withOpacity(0.4)),
                  ),
                  child: Text(
                    advisory.badge,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: activeColor,
                    ),
                  ),
                ),
            ],
          ),
          const Gap(12),
          Text(
            isConnected && advisory != null
                ? advisory.reason
                : 'Connect ESP32 Bluetooth to evaluate helmet microclimate, fogging thresholds, and airflow recommendations.',
            style: GoogleFonts.inter(
              fontSize: 12,
              height: 1.4,
              color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
            ),
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111720) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 13,
                  color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                ),
                const Gap(6),
                Expanded(
                  child: Text(
                    'Advisory only · Fan is controlled manually by rider on Home tab',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Visor Fog Risk & Dew Point Analysis
  Widget _buildVisorFogCard({
    required BuildContext context,
    required bool isDark,
    required Bme680Reading? bme,
    required bool isConnected,
  }) {
    final cardBg = isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final borderCol = isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder;
    final hasSensor = bme != null;

    final temp = bme?.temperature;
    final dewPoint = bme?.dewPoint;
    final margin = bme?.dewPointMargin;
    final isFogRisk = bme?.isVisorFogRisk ?? false;
    final statusColor = hasSensor
        ? (isFogRisk ? const Color(0xFFEF4444) : PureColors.primaryTeal)
        : Colors.grey;

    // Safety margin clamp (0 to 10°C) for progress bar
    final progress = hasSensor ? (margin! / 8.0).clamp(0.05, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.blur_on_rounded, size: 18, color: statusColor),
                  const Gap(8),
                  Text(
                    'HELMET FOG RISK',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                      color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                    ),
                  ),
                  const Gap(6),
                  MathInfoButton(
                    size: 11,
                    color: statusColor,
                    padding: EdgeInsets.zero,
                    onTap: () => _showDewPointMagnusMath(context, bme),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  hasSensor
                      ? (isFogRisk ? '⚠️ FOG WARNING' : '🛡️ HELMET: CLEAR & SAFE')
                      : 'NO SENSOR DATA',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),

          const Gap(16),

          // Safety Margin Progress Bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Safety Buffer Margin',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                ),
              ),
              Text(
                hasSensor
                    ? '+${margin!.toStringAsFixed(1)} °C above Dew Point'
                    : 'Awaiting Sensor Telemetry',
                style: GoogleFonts.sora(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const Gap(8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? Colors.white10 : Colors.black12,
              valueColor: AlwaysStoppedAnimation<Color>(statusColor),
            ),
          ),

          const Gap(18),
          const Divider(height: 1),
          const Gap(16),

          // 4-Quadrant Metric Breakdown
          Row(
            children: [
              _buildFogMetricItem(
                label: 'Helmet Temp',
                value: hasSensor ? '${temp!.toStringAsFixed(1)} °C' : '--',
                isDark: isDark,
              ),
              _buildFogMetricItem(
                label: 'Dew Point',
                value: hasSensor ? '${dewPoint!.toStringAsFixed(1)} °C' : '--',
                isDark: isDark,
              ),
              _buildFogMetricItem(
                label: 'Humidity',
                value: hasSensor ? '${bme.humidity.toStringAsFixed(0)} %' : '--',
                isDark: isDark,
              ),
              _buildFogMetricItem(
                label: 'Fog Margin',
                value: hasSensor ? '+${margin!.toStringAsFixed(1)} °C' : '--',
                isDark: isDark,
                valueColor: statusColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFogMetricItem({
    required String label,
    required String value,
    required bool isDark,
    Color? valueColor,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(fontSize: 10, color: PureColors.textMuted),
          ),
          const Gap(2),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? PureColors.textPrimary : PureColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  /// 3. "Feels Like" Temperature (Heat Index Card)
  Widget _buildHeatIndexCard({
    required BuildContext context,
    required bool isDark,
    required Bme680Reading? bme,
  }) {
    final cardBg = isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final borderCol = isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder;
    final hasSensor = bme != null;

    final hi = bme?.heatIndex;
    final actual = bme?.temperature;
    final comfort = bme?.heatIndexComfort ?? 'Sensor Offline';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.thermostat_auto_rounded, size: 16, color: Color(0xFFFF7A59)),
              const Gap(6),
              Expanded(
                child: Text(
                  'FEELS LIKE',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MathInfoButton(
                size: 11,
                color: const Color(0xFFFF7A59),
                padding: EdgeInsets.zero,
                onTap: () => _showHeatIndexMath(context, bme),
              ),
            ],
          ),
          const Gap(10),
          Text(
            hasSensor ? '${hi!.toStringAsFixed(1)} °C' : '--',
            style: GoogleFonts.sora(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
            ),
          ),
          const Gap(2),
          Text(
            hasSensor ? 'Actual: ${actual!.toStringAsFixed(1)} °C' : 'Actual: --',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
            ),
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFFF7A59).withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              comfort,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFFF7A59),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 4. Exhaled Air & Stale Breath Alert Card
  Widget _buildStaleAirCard({
    required BuildContext context,
    required bool isDark,
    required Bme680Reading? bme,
  }) {
    final cardBg = isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final borderCol = isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder;
    final hasSensor = bme != null;

    final gasRes = bme?.gasResistance;
    final isStale = bme?.isStaleAirWarning ?? false;
    final statusColor = hasSensor
        ? (isStale ? const Color(0xFFF59E0B) : PureColors.primaryTeal)
        : Colors.grey;
    final label = hasSensor
        ? (isStale ? 'Stale Breath Buildup' : 'Fresh Oxygen Flow')
        : 'Awaiting VOC Sensor';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.air_outlined, size: 16, color: statusColor),
              const Gap(6),
              Expanded(
                child: Text(
                  'EXHALED AIR',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MathInfoButton(
                size: 11,
                color: statusColor,
                padding: EdgeInsets.zero,
                onTap: () => _showVocGasMath(context, bme),
              ),
            ],
          ),
          const Gap(10),
          Text(
            hasSensor ? (isStale ? 'STALE' : 'FRESH') : '--',
            style: GoogleFonts.sora(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: statusColor,
            ),
          ),
          const Gap(2),
          Text(
            hasSensor ? 'VOC Res: ${gasRes!.toStringAsFixed(1)} kΩ' : 'VOC Res: --',
            style: GoogleFonts.inter(
              fontSize: 11,
              color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
            ),
          ),
          const Gap(10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  /// 5. Atmospheric & Altitude Diagnostics Card
  Widget _buildAtmosphericCard({
    required BuildContext context,
    required bool isDark,
    required Bme680Reading? bme,
    required bool isConnected,
  }) {
    final cardBg = isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final borderCol = isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder;
    final hasSensor = bme != null;

    final pressure = bme?.pressure;
    final altitude = bme?.altitude;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: borderCol),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.terrain_rounded,
              size: 20,
              color: Color(0xFF8B5CF6),
            ),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Atmospheric & Altitude Diagnostics',
                        style: GoogleFonts.sora(fontSize: 13, fontWeight: FontWeight.w600),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    MathInfoButton(
                      size: 11,
                      color: const Color(0xFF8B5CF6),
                      padding: EdgeInsets.zero,
                      onTap: () => _showAltitudeHypsometricMath(context, bme),
                    ),
                  ],
                ),
                const Gap(2),
                Text(
                  hasSensor
                      ? 'Pressure: ${pressure!.toStringAsFixed(1)} hPa · Alt: ${altitude!.toStringAsFixed(1)} m · Trend: Live'
                      : 'Barometric & Altitude Telemetry · Awaiting ESP32 Link',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDewPointMagnusMath(BuildContext context, Bme680Reading? bme) {
    final temp = bme?.temperature;
    final hum = bme?.humidity;
    final dewPoint = bme?.dewPoint;
    final margin = bme?.dewPointMargin;
    final isFog = bme?.isVisorFogRisk ?? false;

    showMathCalculationDialog(
      context: context,
      title: 'Magnus-Tetens Dew Point Equation',
      icon: Icons.blur_on_rounded,
      accentColor: isFog ? const Color(0xFFEF4444) : PureColors.primaryTeal,
      description:
          'Computes the saturation temperature where water vapor from rider respiration condenses on the helmet shield, predicting fog before it impairs vision.',
      formula:
          'α = ((17.27 × T) / (237.7 + T)) + ln(RH / 100)\nT_dewpoint = (237.7 × α) / (17.27 - α)\nSafety Margin = T_helmet - T_dewpoint',
      variables: [
        MathVariable(
          label: 'Helmet Temperature (T)',
          value: temp != null ? '${temp.toStringAsFixed(1)} °C' : 'Awaiting sensor',
          description: 'Internal dry-bulb air temperature inside helmet',
        ),
        MathVariable(
          label: 'Helmet Relative Humidity (RH)',
          value: hum != null ? '${hum.toStringAsFixed(0)} %' : 'Awaiting sensor',
          description: 'Exhaled moisture concentration',
        ),
        MathVariable(
          label: 'Calculated Dew Point (T_dewpoint)',
          value: dewPoint != null ? '${dewPoint.toStringAsFixed(1)} °C' : 'Awaiting sensor',
          description: 'Temperature where air reaches 100% saturation',
        ),
      ],
      calculationStep: (temp != null && dewPoint != null && margin != null)
          ? 'Margin = ${temp.toStringAsFixed(1)} °C - ${dewPoint.toStringAsFixed(1)} °C = +${margin.toStringAsFixed(1)} °C buffer'
          : 'Live sensor telemetry required for evaluation',
      result: bme != null
          ? (isFog
              ? '⚠️ Fog Alert: Helmet shield within 2.5 °C of condensation'
              : '🛡️ Helmet: Clear (+${margin?.toStringAsFixed(1)} °C safe margin)')
          : 'Awaiting ESP32 Bluetooth link',
      standard: 'Magnus-Tetens Approximation / NOAA National Weather Service',
    );
  }

  void _showHeatIndexMath(BuildContext context, Bme680Reading? bme) {
    final temp = bme?.temperature;
    final hum = bme?.humidity;
    final hi = bme?.heatIndex;
    final comfort = bme?.heatIndexComfort;

    showMathCalculationDialog(
      context: context,
      title: 'Apparent Heat Index ("Feels Like")',
      icon: Icons.thermostat_auto_rounded,
      accentColor: const Color(0xFFFF7A59),
      description:
          'Quantifies the perceived temperature inside the sealed helmet by combining dry-bulb ambient temperature and water vapor pressure from perspiration.',
      formula:
          'e = (RH / 100) × 6.105 × exp((17.27 × T) / (237.7 + T))\nHI = T + (0.33 × e) - 0.70',
      variables: [
        MathVariable(
          label: 'Helmet Temperature (T)',
          value: temp != null ? '${temp.toStringAsFixed(1)} °C' : 'Awaiting sensor',
          description: 'Internal air temperature measured by BME680',
        ),
        MathVariable(
          label: 'Relative Humidity (RH)',
          value: hum != null ? '${hum.toStringAsFixed(0)} %' : 'Awaiting sensor',
          description: 'Perspiration and ambient moisture humidity',
        ),
      ],
      calculationStep: (temp != null && hi != null)
          ? 'Vapor pressure e evaluated → HI = ${hi.toStringAsFixed(1)} °C'
          : 'Pending sensor stream',
      result: hi != null
          ? 'Feels Like ${hi.toStringAsFixed(1)} °C · ${comfort ?? "Optimal"}'
          : 'Awaiting sensor data',
      standard: 'Steadman Apparent Temperature & OSHA Heat Stress Index',
    );
  }

  void _showVocGasMath(BuildContext context, Bme680Reading? bme) {
    final gasRes = bme?.gasResistance;
    final isStale = bme?.isStaleAirWarning ?? false;
    final status = bme?.staleAirStatus;

    showMathCalculationDialog(
      context: context,
      title: 'Metal-Oxide Gas Resistance Index',
      icon: Icons.air_outlined,
      accentColor: isStale ? const Color(0xFFF59E0B) : PureColors.primaryTeal,
      description:
          'The Bosch BME680 heated metal-oxide (MOX) semiconductor changes internal resistance in response to reducing gases, breath VOCs, and carbon dioxide buildup.',
      formula:
          'R_gas > 50 kΩ → Fresh Oxygen Circulation\n20 kΩ < R_gas ≤ 50 kΩ → Moderate Breath VOCs\nR_gas ≤ 20 kΩ → Stale Breath Accumulation',
      variables: [
        MathVariable(
          label: 'Gas Sensor Resistance (R_gas)',
          value: gasRes != null ? '${gasRes.toStringAsFixed(1)} kΩ' : 'Awaiting sensor',
          description: 'Resistance across heated tin-oxide (SnO2) sensing layer',
        ),
      ],
      calculationStep: gasRes != null
          ? 'Measured R_gas = ${gasRes.toStringAsFixed(1)} kΩ → ${gasRes > 50.0 ? "Threshold > 50 kΩ" : (gasRes > 20.0 ? "Threshold 20-50 kΩ" : "Threshold ≤ 20 kΩ")}'
          : 'Awaiting ESP32 sensor link',
      result: bme != null ? (status ?? 'Normal Air') : 'Awaiting Sensor',
      standard: 'Bosch Sensortec BSEC Air Quality Classification',
    );
  }

  void _showAltitudeHypsometricMath(BuildContext context, Bme680Reading? bme) {
    final p = bme?.pressure;
    final alt = bme?.altitude;

    showMathCalculationDialog(
      context: context,
      title: 'Barometric Hypsometric Altitude',
      icon: Icons.terrain_rounded,
      accentColor: const Color(0xFF8B5CF6),
      description:
          'Derives accurate elevation above sea level from ambient barometric pressure measured by the helmet\'s piezoresistive pressure cell.',
      formula:
          'Altitude (m) = 44330 × (1 - (P / P_0)^(1 / 5.255))\nReference Sea-Level Pressure P_0 = 1013.25 hPa',
      variables: [
        MathVariable(
          label: 'Barometric Pressure (P)',
          value: p != null ? '${p.toStringAsFixed(1)} hPa' : 'Awaiting sensor',
          description: 'Atmospheric pressure measured at current elevation',
        ),
        MathVariable(
          label: 'Standard Sea-Level Pressure (P_0)',
          value: '1013.25 hPa',
          description: 'Standard international atmospheric sea-level datum',
        ),
      ],
      calculationStep: p != null
          ? '44330 × (1 - (${p.toStringAsFixed(1)} / 1013.25)^0.190284) = ${alt != null ? alt.toStringAsFixed(1) : "--"} m'
          : 'Pending barometric pressure input',
      result: alt != null
          ? 'Elevation: ${alt.toStringAsFixed(1)} meters above sea level'
          : 'Awaiting sensor data',
      standard: 'ICAO International Standard Atmosphere (Doc 7488/3)',
    );
  }
}
