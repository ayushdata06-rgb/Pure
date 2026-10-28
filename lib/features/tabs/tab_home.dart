import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/colors.dart';
import '../../data/models/bme680_reading.dart';
import '../../data/models/outdoor_data.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/outdoor_provider.dart';
import '../../widgets/math_info_dialog.dart';

class TabHome extends ConsumerStatefulWidget {
  const TabHome({super.key});

  @override
  ConsumerState<TabHome> createState() => _TabHomeState();
}

class _TabHomeState extends ConsumerState<TabHome>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fanAnimController;

  @override
  void initState() {
    super.initState();
    _fanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );
  }

  @override
  void dispose() {
    _fanAnimController.dispose();
    super.dispose();
  }

  void _triggerFanCommand(bool turnOn) {
    HapticFeedback.mediumImpact();
    // Send signal strictly through ESP32 Bluetooth Classic
    sendFanCommand(ref, turnOn);
  }

  @override
  Widget build(BuildContext context) {
    final bme = ref.watch(latestBme680Provider);
    final outdoor = ref.watch(outdoorDataProvider);
    final btService = ref.watch(bluetoothServiceProvider);
    final isFanOn = ref.watch(fanStateProvider);
    final lastCommand = ref.watch(lastFanCommandProvider);
    final isConnected = btService.isConnected;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Animate fan rotation when active
    if (isFanOn && !_fanAnimController.isAnimating) {
      _fanAnimController.repeat();
    } else if (!isFanOn && _fanAnimController.isAnimating) {
      _fanAnimController.stop();
    }

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ==========================================
          // 1. HERO: DUAL-ZONE AQI COMPARISON
          // ==========================================
          _buildDualZoneAqiCard(
            isDark: isDark,
            bme: bme,
            outdoor: outdoor,
            isConnected: isConnected,
            isFanOn: isFanOn,
          ),

          const Gap(16),

          // ==========================================
          // 2. HELMET AIR PURIFIER BLOWER (TAP TO TOGGLE)
          // ==========================================
          _buildCircularBlowerCard(
            isDark: isDark,
            isFanOn: isFanOn,
            isConnected: isConnected,
            lastCommand: lastCommand,
          ),

          const Gap(16),

          // ==========================================
          // 3. DUAL-ZONE MICROCLIMATE (TEMP & HUMIDITY)
          // ==========================================
          _buildMicroclimateSection(
            isDark: isDark,
            bme: bme,
            outdoor: outdoor,
          ),

          const Gap(16),
        ],
      ),
    );
  }

  /// 1. Hero Dual-Zone AQI Comparison Widget
  Widget _buildDualZoneAqiCard({
    required bool isDark,
    required Bme680Reading? bme,
    required OutdoorData outdoor,
    required bool isConnected,
    required bool isFanOn,
  }) {
    final activeTeal = PureColors.primaryTeal;
    final cardBg = isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final borderCol = isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder;

    final hasSensor = bme != null;
    final int? insideAqi = bme?.calculatedAqi;
    final outsideAqi = outdoor.aqi;

    // Calculate protection efficiency percentage with real readings
    int cleanerPct = 0;
    if (hasSensor && outsideAqi > 0 && insideAqi != null) {
      final delta = outsideAqi - insideAqi;
      cleanerPct = ((delta / outsideAqi) * 100).clamp(0, 99).toInt();
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderCol),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.35 : 0.05),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section Title
          Row(
            children: [
              Expanded(
                child: Text(
                  'AIR PURITY COMPARISON',
                  style: GoogleFonts.inter(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: activeTeal.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 12, color: activeTeal),
                    const Gap(4),
                    Text(
                      hasSensor && cleanerPct > 0
                          ? '$cleanerPct% CLEANER'
                          : (hasSensor
                              ? 'PURIFIER ACTIVE'
                              : (isConnected ? 'READING...' : 'SENSOR OFFLINE')),
                      style: GoogleFonts.sora(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: activeTeal,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(18),

          // Side-by-Side Comparison Columns
          Row(
            children: [
              // Left: Inside Helmet
              Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showInsideAqiMath(
                      context,
                      bme: bme,
                      insideAqi: insideAqi,
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: activeTeal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: activeTeal.withOpacity(0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.health_and_safety_rounded, size: 15, color: activeTeal),
                              const Gap(5),
                              Expanded(
                                child: Text(
                                  'HELMET AQI',
                                  style: GoogleFonts.inter(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: activeTeal,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              MathInfoButton(
                                size: 11,
                                color: activeTeal,
                                padding: EdgeInsets.zero,
                                onTap: () => _showInsideAqiMath(
                                  context,
                                  bme: bme,
                                  insideAqi: insideAqi,
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Text(
                            hasSensor ? '$insideAqi' : '--',
                            style: GoogleFonts.sora(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1,
                              color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            hasSensor
                                ? 'AQI · ${bme.airQualityLabel}'
                                : (isConnected ? 'Reading Sensor...' : 'Awaiting ESP32'),
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: activeTeal,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const Gap(12),

              // Right: Outside City Air (GPS)
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: (outsideAqi > 100 ? Colors.orangeAccent : Colors.blueAccent)
                        .withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: (outsideAqi > 100 ? Colors.orangeAccent : Colors.blueAccent)
                          .withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.public_rounded,
                            size: 15,
                            color: outsideAqi > 100 ? Colors.orangeAccent : Colors.blueAccent,
                          ),
                          const Gap(6),
                          Expanded(
                            child: Text(
                              'OUTSIDE (GPS)',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: outsideAqi > 100 ? Colors.orangeAccent : Colors.blueAccent,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        outsideAqi > 0 ? '$outsideAqi' : '--',
                        style: GoogleFonts.sora(
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        outsideAqi > 0
                            ? 'AQI · ${outdoor.aqiStatus}'
                            : 'Acquiring GPS...',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: outsideAqi > 100 ? Colors.orangeAccent : Colors.blueAccent,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Gap(14),

          // Dynamic Advisory Note
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF111720) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  outsideAqi > 100 ? Icons.warning_amber_rounded : Icons.verified_rounded,
                  size: 16,
                  color: outsideAqi > 100 ? Colors.orangeAccent : activeTeal,
                ),
                const Gap(8),
                Expanded(
                  child: Text(
                    outsideAqi > 100
                        ? (isFanOn
                            ? 'Outside air is polluted ($outsideAqi AQI). Helmet filter is maintaining clean airflow.'
                            : 'Outside air is polluted ($outsideAqi AQI). Turn on fan to maintain positive pressure.')
                        : 'Ambient city air is moderate. Helmet microclimate is optimal.',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
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

  /// 2. Helmet Air Purifier Circular Blower Station (Interactive Tap-to-Toggle)
  Widget _buildCircularBlowerCard({
    required bool isDark,
    required bool isFanOn,
    required bool isConnected,
    required String? lastCommand,
  }) {
    final activeTeal = PureColors.primaryTeal;
    final cardBg = isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final borderCol = isFanOn
        ? activeTeal.withOpacity(0.5)
        : (isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol, width: isFanOn ? 1.5 : 1.0),
        boxShadow: isFanOn
            ? [
                BoxShadow(
                  color: activeTeal.withOpacity(0.18),
                  blurRadius: 28,
                  spreadRadius: 2,
                  offset: const Offset(0, 6),
                ),
              ]
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.05),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isFanOn
                          ? activeTeal.withOpacity(0.16)
                          : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.air_rounded,
                      size: 18,
                      color: isFanOn ? activeTeal : (isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  const Gap(10),
                  Text(
                    'HELMET PURIFIER',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                      color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
              // Status Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isFanOn
                      ? activeTeal.withOpacity(0.15)
                      : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isFanOn
                        ? activeTeal.withOpacity(0.45)
                        : (isDark ? Colors.white12 : Colors.black12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isFanOn ? activeTeal : Colors.grey,
                      ),
                    ),
                    const Gap(6),
                    Text(
                      isFanOn ? 'ACTIVE' : 'STANDBY',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: isFanOn
                            ? activeTeal
                            : (isDark ? PureColors.textMuted : PureColors.lightTextMuted),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(22),

          // ========================================================
          // INTERACTIVE CIRCULAR BLOWER TURBINE (TAP TO TOGGLE ON/OFF)
          // ========================================================
          GestureDetector(
            onTap: () => _triggerFanCommand(!isFanOn),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Outer Pulsing Aura / Radial Glow when ON
                AnimatedContainer(
                  duration: const Duration(milliseconds: 350),
                  width: 204,
                  height: 204,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: isFanOn
                        ? [
                            BoxShadow(
                              color: activeTeal.withOpacity(0.28),
                              blurRadius: 36,
                              spreadRadius: 4,
                            ),
                            BoxShadow(
                              color: const Color(0xFF3B9DFF).withOpacity(0.18),
                              blurRadius: 20,
                            ),
                          ]
                        : [],
                  ),
                ),

                // Concentric Outer Stator Housing
                Container(
                  width: 196,
                  height: 196,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF0C141B) : const Color(0xFFE8EEF2),
                    border: Border.all(
                      color: isFanOn
                          ? activeTeal.withOpacity(0.65)
                          : (isDark ? Colors.white12 : Colors.black12),
                      width: isFanOn ? 2.5 : 1.5,
                    ),
                  ),
                ),

                // Intermediate Air Inlet Ring
                Container(
                  width: 174,
                  height: 174,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFanOn
                          ? activeTeal.withOpacity(0.25)
                          : (isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04)),
                      width: 1.5,
                    ),
                  ),
                ),

                // Revolving Centrifugal Blower Impeller Blades
                AnimatedBuilder(
                  animation: _fanAnimController,
                  builder: (context, _) {
                    return CustomPaint(
                      size: const Size(180, 180),
                      painter: _BlowerImpellerPainter(
                        angle: _fanAnimController.value * 2 * math.pi,
                        isFanOn: isFanOn,
                        activeColor: activeTeal,
                      ),
                    );
                  },
                ),

                // Center Tactile Power Hub Trigger
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isFanOn ? activeTeal : (isDark ? const Color(0xFF16232D) : const Color(0xFFD9E2E8)),
                    border: Border.all(
                      color: isFanOn ? Colors.white : (isDark ? Colors.white24 : Colors.black12),
                      width: 2.0,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                      if (isFanOn)
                        BoxShadow(
                          color: activeTeal.withOpacity(0.6),
                          blurRadius: 18,
                        ),
                    ],
                  ),
                  child: Center(
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      size: 32,
                      color: isFanOn ? Colors.black : (isDark ? Colors.white70 : Colors.black87),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Gap(20),

          // Main Action Title
          Text(
            isFanOn ? 'AIR PURIFIER ACTIVE' : 'PURIFIER STANDBY',
            style: GoogleFonts.sora(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.6,
              color: isFanOn
                  ? activeTeal
                  : (isDark ? PureColors.textPrimary : PureColors.lightTextPrimary),
            ),
          ),
          const Gap(6),

          // Interactive Tap Prompt
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.touch_app_rounded,
                size: 15,
                color: isFanOn ? activeTeal.withOpacity(0.85) : activeTeal,
              ),
              const Gap(5),
              Text(
                isFanOn ? 'Tap blower to turn off' : 'Tap blower to turn on',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: isFanOn
                      ? (isDark ? PureColors.textSecondary : PureColors.lightTextSecondary)
                      : activeTeal,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// 3. Dual-Zone Microclimate (Temperature & Humidity Inside vs Outside)
  Widget _buildMicroclimateSection({
    required bool isDark,
    required Bme680Reading? bme,
    required OutdoorData outdoor,
  }) {
    final hasSensor = bme != null;
    final insideTemp = bme?.temperature;
    final outsideTemp = outdoor.temperature;
    final tempDelta = (insideTemp != null) ? (outsideTemp - insideTemp) : null;

    final insideHum = bme?.humidity;
    final outsideHum = outdoor.humidity;

    final isFogRisk = bme?.isVisorFogRisk ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'MICROCLIMATE COMPARISON',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
          ),
        ),
        const Gap(12),
        Row(
          children: [
            // Card A: Temperature Comparison
            Expanded(
              child: _buildComparisonCard(
                isDark: isDark,
                icon: Icons.thermostat_rounded,
                iconColor: const Color(0xFFFF7A59),
                title: 'TEMPERATURE',
                insideLabel: insideTemp != null ? '${insideTemp.toStringAsFixed(1)}°C' : '--',
                outsideLabel: '${outsideTemp.toStringAsFixed(1)}°C',
                deltaText: tempDelta != null
                    ? (tempDelta > 0
                        ? '❄️ ${tempDelta.abs().toStringAsFixed(1)}°C Cooler'
                        : '🔥 ${tempDelta.abs().toStringAsFixed(1)}°C Warmer')
                    : 'Awaiting Sensor',
                deltaColor: tempDelta != null
                    ? (tempDelta > 0 ? PureColors.primaryTeal : Colors.orangeAccent)
                    : Colors.grey,
                onInfoTap: () => _showTemperatureMath(
                  context,
                  outsideTemp: outsideTemp,
                  insideTemp: insideTemp,
                  tempDelta: tempDelta,
                ),
              ),
            ),

            const Gap(12),

            // Card B: Humidity & Visor Fog Risk
            Expanded(
              child: _buildComparisonCard(
                isDark: isDark,
                icon: Icons.water_drop_rounded,
                iconColor: const Color(0xFF4A90E2),
                title: 'HUMIDITY',
                insideLabel: insideHum != null ? '${insideHum.toStringAsFixed(0)}%' : '--',
                outsideLabel: '${outsideHum.toStringAsFixed(0)}%',
                deltaText: hasSensor
                    ? (isFogRisk ? '⚠️ Helmet Fog Risk' : '🛡️ Helmet: Clear')
                    : 'Awaiting Sensor',
                deltaColor: hasSensor
                    ? (isFogRisk ? Colors.redAccent : PureColors.primaryTeal)
                    : Colors.grey,
                onInfoTap: () => _showFogRiskMath(
                  context,
                  bme: bme,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildComparisonCard({
    required bool isDark,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String insideLabel,
    required String outsideLabel,
    required String deltaText,
    required Color deltaColor,
    VoidCallback? onInfoTap,
  }) {
    final cardBg = isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final borderCol = isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: iconColor),
              const Gap(6),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                    color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onInfoTap != null)
                MathInfoButton(
                  size: 11,
                  color: iconColor,
                  padding: EdgeInsets.zero,
                  onTap: onInfoTap,
                ),
            ],
          ),
          const Gap(12),
          // Inside vs Outside Values
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Inside',
                    style: GoogleFonts.inter(fontSize: 10, color: PureColors.textMuted),
                  ),
                  Text(
                    insideLabel,
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                width: 1,
                height: 26,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Outside',
                    style: GoogleFonts.inter(fontSize: 10, color: PureColors.textMuted),
                  ),
                  Text(
                    outsideLabel,
                    style: GoogleFonts.sora(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const Gap(10),
          // Bottom Delta Badge
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: deltaColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              deltaText,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: deltaColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showInsideAqiMath(
    BuildContext context, {
    required Bme680Reading? bme,
    required int? insideAqi,
  }) {
    final gasRes = bme?.gasResistance;
    final hum = bme?.humidity;
    final temp = bme?.temperature;

    showMathCalculationDialog(
      context: context,
      title: 'Inside Helmet Air Quality Index (AQI)',
      icon: Icons.health_and_safety_rounded,
      accentColor: PureColors.primaryTeal,
      description:
          'Computes breathable air quality inside the sealed helmet visor using the Bosch BME680 metal-oxide (MOX) gas sensor. Higher gas resistance indicates cleaner air with fewer volatile organic compounds (VOCs).',
      formula:
          'R_gas ≥ 80 kΩ  → AQI = 22 (Excellent Air)\n'
          '50 ≤ R_gas < 80 kΩ → AQI = 38 (Good Air)\n'
          '30 ≤ R_gas < 50 kΩ → AQI = 65 (Moderate Air)\n'
          '20 ≤ R_gas < 30 kΩ → AQI = 98 (Slight Breath VOCs)\n'
          '10 ≤ R_gas < 20 kΩ → AQI = 145 (Stale Exhaled Air)\n'
          'R_gas < 10 kΩ  → AQI = 210 (High Pollution / VOCs)',
      variables: [
        MathVariable(
          label: 'VOC Gas Resistance (R_gas)',
          value: gasRes != null ? '${gasRes.toStringAsFixed(1)} kΩ' : 'Awaiting sensor',
          description: 'Resistance across heated tin-oxide (SnO2) sensing layer',
        ),
        MathVariable(
          label: 'Helmet Relative Humidity (RH)',
          value: hum != null ? '${hum.toStringAsFixed(0)} %' : 'Awaiting sensor',
          description: 'Exhaled breath moisture inside helmet',
        ),
        MathVariable(
          label: 'Helmet Temperature (T)',
          value: temp != null ? '${temp.toStringAsFixed(1)} °C' : 'Awaiting sensor',
          description: 'Internal helmet microclimate temperature',
        ),
      ],
      calculationStep: gasRes != null
          ? 'Measured R_gas = ${gasRes.toStringAsFixed(1)} kΩ → '
              '${gasRes >= 80.0 ? "Tier ≥ 80 kΩ (Optimal baseline)" : (gasRes >= 50.0 ? "Tier 50–80 kΩ (Clean filtered air)" : (gasRes >= 30.0 ? "Tier 30–50 kΩ (Moderate breath accumulation)" : "Tier < 30 kΩ (Elevated VOCs)"))}'
          : 'Awaiting ESP32 live telemetry stream',
      result: insideAqi != null
          ? '$insideAqi AQI · ${bme?.airQualityLabel ?? "Normal Air"}'
          : 'Awaiting ESP32 Sensor Link',
      standard: 'Bosch Sensortec BSEC Air Quality Index & EPA AQI Mapping',
    );
  }

  void _showTemperatureMath(
    BuildContext context, {
    required double outsideTemp,
    required double? insideTemp,
    required double? tempDelta,
  }) {
    showMathCalculationDialog(
      context: context,
      title: 'Microclimate Temperature Delta (ΔT)',
      icon: Icons.thermostat_rounded,
      accentColor: const Color(0xFFFF7A59),
      description:
          'Evaluates convective cooling inside the sealed helmet achieved through positive pressure blower displacement over the rider\'s face.',
      formula: 'ΔT = T_outdoor - T_helmet',
      variables: [
        MathVariable(
          label: 'Outdoor Road Temp (T_outdoor)',
          value: '${outsideTemp.toStringAsFixed(1)} °C',
          description: 'Live ambient road thermal reading from weather station',
        ),
        MathVariable(
          label: 'Inside Helmet Temp (T_helmet)',
          value: insideTemp != null ? '${insideTemp.toStringAsFixed(1)} °C' : 'Awaiting Sensor',
          description: 'Direct internal BME680 thermal probe reading',
        ),
      ],
      calculationStep: insideTemp != null
          ? '${outsideTemp.toStringAsFixed(1)} °C - ${insideTemp.toStringAsFixed(1)} °C = ${(outsideTemp - insideTemp).toStringAsFixed(1)} °C'
          : 'Awaiting internal sensor telemetry stream',
      result: tempDelta != null
          ? (tempDelta > 0
              ? '❄️ ${tempDelta.abs().toStringAsFixed(1)} °C Cooler inside helmet'
              : '🔥 ${tempDelta.abs().toStringAsFixed(1)} °C Warmer inside helmet')
          : 'Awaiting sensor synchronization',
      standard: 'ISO 7730 Ergonomics of Thermal Environment & Microclimate',
    );
  }

  void _showFogRiskMath(
    BuildContext context, {
    required Bme680Reading? bme,
  }) {
    final temp = bme?.temperature;
    final dewPoint = bme?.dewPoint;
    final margin = bme?.dewPointMargin;
    final isFogRisk = bme?.isVisorFogRisk ?? false;

    showMathCalculationDialog(
      context: context,
      title: 'Helmet Condensation & Fog Risk Threshold',
      icon: Icons.water_drop_rounded,
      accentColor: const Color(0xFF4A90E2),
      description:
          'Moisture in exhaled breath condenses into fog on the helmet shield when inner shield temperature approaches the dew point. A safety buffer of at least 2.5 °C prevents condensation.',
      formula: 'Fog Safety Buffer = T_helmet - T_dew_point\nAlert Condition: Buffer < 2.5 °C',
      variables: [
        MathVariable(
          label: 'Helmet Temperature (T_helmet)',
          value: temp != null ? '${temp.toStringAsFixed(1)} °C' : 'Awaiting sensor',
          description: 'Internal helmet air temperature',
        ),
        MathVariable(
          label: 'Exhaled Dew Point (T_dew_point)',
          value: dewPoint != null ? '${dewPoint.toStringAsFixed(1)} °C' : 'Awaiting sensor',
          description: 'Magnus-Tetens condensation saturation point',
        ),
        MathVariable(
          label: 'Safety Buffer Margin',
          value: margin != null ? '+${margin.toStringAsFixed(1)} °C' : 'Awaiting sensor',
          description: 'Temperature buffer above fogging threshold',
        ),
      ],
      calculationStep: (temp != null && dewPoint != null && margin != null)
          ? '${temp.toStringAsFixed(1)} °C - ${dewPoint.toStringAsFixed(1)} °C = ${margin.toStringAsFixed(1)} °C buffer'
          : 'Telemetry stream required for live calculation',
      result: bme != null
          ? (isFogRisk
              ? '⚠️ High Fog Risk: Helmet requires ventilation blower'
              : '🛡️ Helmet: Clear (+${margin?.toStringAsFixed(1)} °C safe margin)')
          : 'Awaiting ESP32 sensor link',
      standard: 'WMO Guide to Meteorological Instruments & Observation #8',
    );
  }
}

/// Aerodynamic Centrifugal Blower Impeller Custom Painter
class _BlowerImpellerPainter extends CustomPainter {
  final double angle;
  final bool isFanOn;
  final Color activeColor;

  _BlowerImpellerPainter({
    required this.angle,
    required this.isFanOn,
    required this.activeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer guide circular track
    final guidePaint = Paint()
      ..color = (isFanOn ? activeColor : Colors.white12).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    canvas.drawCircle(center, radius - 3, guidePaint);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    const int bladeCount = 9;
    final innerR = radius * 0.38;
    final outerR = radius * 0.90;

    for (int i = 0; i < bladeCount; i++) {
      final bladeAngle = (i * 2 * math.pi) / bladeCount;
      final path = Path();

      final start = Offset(innerR * math.cos(bladeAngle), innerR * math.sin(bladeAngle));
      final tip = Offset(
        outerR * math.cos(bladeAngle + 0.55),
        outerR * math.sin(bladeAngle + 0.55),
      );
      final controlPoint1 = Offset(
        (innerR + (outerR - innerR) * 0.5) * math.cos(bladeAngle + 0.15),
        (innerR + (outerR - innerR) * 0.5) * math.sin(bladeAngle + 0.15),
      );
      final backTip = Offset(
        outerR * 0.96 * math.cos(bladeAngle + 0.65),
        outerR * 0.96 * math.sin(bladeAngle + 0.65),
      );
      final controlPoint2 = Offset(
        (innerR + (outerR - innerR) * 0.5) * math.cos(bladeAngle + 0.35),
        (innerR + (outerR - innerR) * 0.5) * math.sin(bladeAngle + 0.35),
      );

      path.moveTo(start.dx, start.dy);
      path.quadraticBezierTo(controlPoint1.dx, controlPoint1.dy, tip.dx, tip.dy);
      path.lineTo(backTip.dx, backTip.dy);
      path.quadraticBezierTo(controlPoint2.dx, controlPoint2.dy, start.dx, start.dy);
      path.close();

      final bladePaint = Paint()
        ..style = PaintingStyle.fill
        ..shader = RadialGradient(
          colors: isFanOn
              ? [
                  activeColor.withOpacity(0.95),
                  activeColor.withOpacity(0.45),
                  const Color(0xFF3B9DFF).withOpacity(0.25),
                ]
              : [
                  Colors.white.withOpacity(0.35),
                  Colors.white.withOpacity(0.12),
                  Colors.white.withOpacity(0.04),
                ],
        ).createShader(Rect.fromCircle(center: Offset.zero, radius: outerR));

      canvas.drawPath(path, bladePaint);

      final ridgePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0
        ..color = isFanOn ? activeColor.withOpacity(0.7) : Colors.white24;
      canvas.drawPath(path, ridgePaint);
    }

    // Inner hub backing disc
    final hubPaint = Paint()
      ..color = const Color(0xFF0A0F14)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset.zero, innerR, hubPaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _BlowerImpellerPainter oldDelegate) {
    return oldDelegate.angle != angle ||
        oldDelegate.isFanOn != isFanOn ||
        oldDelegate.activeColor != activeColor;
  }
}
