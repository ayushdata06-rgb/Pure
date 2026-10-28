import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/theme/colors.dart';
import '../../data/models/ride_session.dart';
import '../../providers/ride_session_provider.dart';
import '../../widgets/math_info_dialog.dart';

class TabHistory extends ConsumerWidget {
  const TabHistory({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionState = ref.watch(rideSessionProvider);
    final active = sessionState.activeSession;
    final past = sessionState.pastSessions;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // ==========================================
          // 1. LIFETIME PROTECTION SUMMARY
          // ==========================================
          _buildLifetimeStatsCard(
            context: context,
            isDark: isDark,
            totalRides: sessionState.totalRides,
            totalLiters: sessionState.totalCleanAirLiters,
            avgEfficiency: sessionState.averageEfficiency,
          ),

          const Gap(16),

          // ==========================================
          // 2. ACTIVE RIDE BANNER (IF FAN IS ON)
          // ==========================================
          if (active != null) ...[
            _buildActiveRideBanner(
              context: context,
              isDark: isDark,
              activeSession: active,
            ),
            const Gap(16),
          ],

          // ==========================================
          // 3. PAST RIDE SESSIONS LIST
          // ==========================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PAST RIDE SESSIONS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${past.length} LOGGED',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                  ),
                ),
              ),
            ],
          ),

          const Gap(12),

          if (past.isEmpty)
            _buildEmptyState(isDark)
          else
            ...past.map((session) => _buildRideCard(
                  context: context,
                  isDark: isDark,
                  session: session,
                )),

          const Gap(14),
        ],
      ),
    );
  }

  /// 1. Top Lifetime Cumulative Summary Card
  Widget _buildLifetimeStatsCard({
    required BuildContext context,
    required bool isDark,
    required int totalRides,
    required int totalLiters,
    required int avgEfficiency,
  }) {
    final cardBg = isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final borderCol = isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder;
    final activeTeal = PureColors.primaryTeal;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 18),
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
          Row(
            children: [
              Icon(Icons.workspace_premium_rounded, size: 18, color: activeTeal),
              const Gap(8),
              Text(
                'HELMET EFFICIENCY SUMMARY',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const Gap(16),
          Row(
            children: [
              // Total Commutes
              _buildStatTile(
                title: 'COMMUTES',
                value: '$totalRides',
                subtitle: 'Total trips',
                isDark: isDark,
              ),
              Container(
                width: 1,
                height: 38,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              // Clean Air Volume
              _buildStatTile(
                title: 'CLEAN AIR',
                value: '${NumberFormat('#,###').format(totalLiters)} L',
                subtitle: 'Volume pushed',
                valueColor: activeTeal,
                isDark: isDark,
                onInfoTap: () => _showAirDeliveredMath(
                  context,
                  totalLiters: totalLiters,
                ),
              ),
              Container(
                width: 1,
                height: 38,
                color: isDark ? Colors.white12 : Colors.black12,
              ),
              // All-Time Efficiency
              _buildStatTile(
                title: 'EFFICIENCY',
                value: '$avgEfficiency%',
                subtitle: 'Mean filtered',
                valueColor: const Color(0xFF10B981),
                isDark: isDark,
                onInfoTap: () => _showAvgEfficiencyMath(
                  context,
                  avgEfficiency: avgEfficiency,
                  totalRides: totalRides,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatTile({
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
    Color? valueColor,
    VoidCallback? onInfoTap,
  }) {
    final activeColor = valueColor ?? (isDark ? PureColors.textPrimary : PureColors.lightTextPrimary);

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 8.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.3,
                  color: PureColors.textMuted,
                ),
              ),
              if (onInfoTap != null) ...[
                const Gap(3),
                MathInfoButton(
                  size: 9,
                  color: activeColor,
                  padding: EdgeInsets.zero,
                  onTap: onInfoTap,
                ),
              ],
            ],
          ),
          const Gap(4),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: activeColor,
            ),
          ),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
            ),
          ),
        ],
      ),
    );
  }

  /// 2. Live Active Ride Banner (When Fan is ON)
  Widget _buildActiveRideBanner({
    required BuildContext context,
    required bool isDark,
    required RideSession activeSession,
  }) {
    final activeTeal = PureColors.primaryTeal;
    final dur = activeSession.duration;
    final durMinutes = dur.inMinutes;
    final durSeconds = dur.inSeconds % 60;
    final timeStr = '${durMinutes}m ${durSeconds.toString().padLeft(2, '0')}s';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: activeTeal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: activeTeal.withOpacity(0.4), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: activeTeal.withOpacity(0.15),
            blurRadius: 16,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFEF4444),
                ),
              ),
              const Gap(8),
              Text(
                'LIVE RIDE SESSION IN PROGRESS',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: activeTeal,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: activeTeal.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  timeStr,
                  style: GoogleFonts.sora(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: activeTeal,
                  ),
                ),
              ),
            ],
          ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Filtration: ${activeSession.filtrationEfficiency}%',
                    style: GoogleFonts.sora(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                    ),
                  ),
                  const Gap(4),
                  MathInfoButton(
                    size: 9,
                    color: activeTeal,
                    padding: EdgeInsets.zero,
                    onTap: () => _showRideEfficiencyMath(context, session: activeSession),
                  ),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '~${activeSession.cleanAirVolumeLiters} L Purified',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: activeTeal,
                    ),
                  ),
                  const Gap(4),
                  MathInfoButton(
                    size: 9,
                    color: activeTeal,
                    padding: EdgeInsets.zero,
                    onTap: () => _showRideAirDeliveredMath(context, session: activeSession),
                  ),
                ],
              ),
            ],
          ),
          const Gap(4),
          Text(
            'Logging telemetry every 25s · Session saves automatically on TURN OFF',
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
            ),
          ),
        ],
      ),
    );
  }

  /// 3. Individual Past Ride Card
  Widget _buildRideCard({
    required BuildContext context,
    required bool isDark,
    required RideSession session,
  }) {
    final cardBg = isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final borderCol = isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder;
    final activeTeal = PureColors.primaryTeal;

    final dateStr = DateFormat('EEE, d MMM · hh:mm a').format(session.startTime);
    final durStr = session.duration.inMinutes > 0
        ? '${session.duration.inMinutes} mins'
        : '${session.duration.inSeconds}s';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderCol),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Date & Duration
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                dateStr,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.schedule_rounded, size: 12, color: PureColors.textMuted),
                    const Gap(4),
                    Text(
                      durStr,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Gap(12),

          // Efficiency Banner Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: activeTeal.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: activeTeal.withOpacity(0.25)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.shield_rounded, size: 14, color: activeTeal),
                    const Gap(6),
                    Text(
                      '${session.filtrationEfficiency}% PURIFIED',
                      style: GoogleFonts.sora(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: activeTeal,
                      ),
                    ),
                    const Gap(4),
                    MathInfoButton(
                      size: 9,
                      color: activeTeal,
                      padding: EdgeInsets.zero,
                      onTap: () => _showRideEfficiencyMath(context, session: session),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '~${session.cleanAirVolumeLiters} L Clean Air',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: activeTeal,
                      ),
                    ),
                    const Gap(4),
                    MathInfoButton(
                      size: 9,
                      color: activeTeal,
                      padding: EdgeInsets.zero,
                      onTap: () => _showRideAirDeliveredMath(context, session: session),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Gap(12),

          // Comparison Stats: Inside vs Outside
          Row(
            children: [
              _buildDetailItem(
                label: 'Helmet Avg',
                value: '${session.averageInsideAqi.round()} AQI',
                valueColor: activeTeal,
                isDark: isDark,
              ),
              _buildDetailItem(
                label: 'City Ambient',
                value: '${session.averageOutsideAqi.round()} AQI',
                valueColor: Colors.orangeAccent,
                isDark: isDark,
              ),
              _buildDetailItem(
                label: 'Helmet Temp',
                value: '${session.averageTemperature.toStringAsFixed(1)} °C',
                isDark: isDark,
              ),
              _buildDetailItem(
                label: 'Humidity',
                value: '${session.averageHumidity.toStringAsFixed(0)} %',
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
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
            style: GoogleFonts.inter(
              fontSize: 10,
              color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
            ),
          ),
          const Gap(2),
          Text(
            value,
            style: GoogleFonts.sora(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? (isDark ? PureColors.textPrimary : PureColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? PureColors.darkSurface : PureColors.lightSurface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Center(
        child: Column(
          children: [
            Icon(Icons.history_rounded, size: 36, color: PureColors.textMuted),
            const Gap(10),
            Text(
              'No Ride Sessions Logged Yet',
              style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const Gap(4),
            Text(
              'Turn on the Helmet Fan on the Home screen to begin recording your first ride session.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(fontSize: 12, color: PureColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  void _showAirDeliveredMath(BuildContext context, {required int totalLiters}) {
    showMathCalculationDialog(
      context: context,
      title: 'Clean Air Volume Displacement',
      icon: Icons.air_rounded,
      accentColor: PureColors.primaryTeal,
      description:
          'Measures cumulative purified air pumped through the HEPA/Carbon filtration matrix into the rider\'s breathing space across all commutes.',
      formula:
          'Air Volume (Liters) = Commute Duration (mins) × Impeller Flow Rate\nCentrifugal Impeller Delivery Rate = 8.0 Liters/minute',
      variables: [
        MathVariable(
          label: 'Total Clean Air Delivered',
          value: '${NumberFormat('#,###').format(totalLiters)} Liters',
          description: 'Lifetime cumulative positive-pressure air displacement',
        ),
        MathVariable(
          label: 'Continuous Blower Flow Rate',
          value: '8.0 L/min',
          description: 'Calibrated delivery rate of centrifugal blower',
        ),
      ],
      calculationStep:
          'Cumulative Volume = ${NumberFormat('#,###').format(totalLiters)} L ≈ ${(totalLiters / 8.0).round()} total minutes of positive-pressure clean airflow delivered',
      result: '${NumberFormat('#,###').format(totalLiters)} Liters of Purified Air Delivered',
      standard: 'Resting Adult Inhalation Minute Volume Standard (6–8 L/min)',
    );
  }

  void _showAvgEfficiencyMath(
    BuildContext context, {
    required int avgEfficiency,
    required int totalRides,
  }) {
    showMathCalculationDialog(
      context: context,
      title: 'All-Time Average Filtration Efficiency',
      icon: Icons.shield_rounded,
      accentColor: const Color(0xFF10B981),
      description:
          'Statistical mean of particulate barrier protection across all recorded ride sessions stored in Firebase Firestore.',
      formula:
          'Session Efficiency = ((AQI_outdoor - AQI_visor) / AQI_outdoor) × 100\nLifetime Average = (1 / N) × Σ (Session_Efficiency_i)',
      variables: [
        MathVariable(
          label: 'Completed Rides (N)',
          value: '$totalRides commutes',
          description: 'Total completed sessions recorded in history',
        ),
        MathVariable(
          label: 'Mean Protection Rating',
          value: '$avgEfficiency %',
          description: 'Weighted reduction of hazardous ambient particulates',
        ),
      ],
      calculationStep: totalRides > 0
          ? 'Evaluated across $totalRides logged trips stored in Firestore'
          : 'Pending completed ride session records',
      result: '$avgEfficiency% Average Particulate Reduction',
      standard: 'ISO 29463 High Efficiency Particulate Air Standards',
    );
  }

  void _showRideEfficiencyMath(
    BuildContext context, {
    required RideSession session,
  }) {
    final meanOut = session.averageOutsideAqi.round();
    final meanIn = session.averageInsideAqi.round();

    showMathCalculationDialog(
      context: context,
      title: 'Commute Filtration Efficiency',
      icon: Icons.shield_rounded,
      accentColor: PureColors.primaryTeal,
      description:
          'Running average of particulate reduction calculated across 25-second telemetry snapshots for this specific ride.',
      formula:
          'Filtration Efficiency % = ((Mean_AQI_ambient - Mean_AQI_visor) / Mean_AQI_ambient) × 100',
      variables: [
        MathVariable(
          label: 'Mean Ambient City AQI',
          value: '$meanOut AQI',
          description: 'Average road pollution during ride',
        ),
        MathVariable(
          label: 'Mean Helmet AQI',
          value: '$meanIn AQI',
          description: 'Average air quality breathed inside helmet',
        ),
        MathVariable(
          label: 'Telemetry Snapshots',
          value:
              '${session.dataPoints.isNotEmpty ? session.dataPoints.length : (session.duration.inSeconds / 25).ceil().clamp(1, 999)} points',
          description: 'Recorded every 25 seconds during commute',
        ),
      ],
      calculationStep: meanOut > 0
          ? '(($meanOut - $meanIn) / $meanOut) × 100 = ${((meanOut - meanIn) / meanOut * 100).toStringAsFixed(1)}%'
          : 'Mean calculation complete',
      result: '${session.filtrationEfficiency}% Protection Maintained',
      standard: 'ISO 29463 / EN 1822 Particulate Filtration Standard',
    );
  }

  void _showRideAirDeliveredMath(
    BuildContext context, {
    required RideSession session,
  }) {
    showMathCalculationDialog(
      context: context,
      title: 'Session Clean Air Volume Displacement',
      icon: Icons.air_rounded,
      accentColor: PureColors.primaryTeal,
      description:
          'Calculates the exact volume of HEPA-filtered air pumped into the helmet cavity during this specific ride commute.',
      formula: 'Air Volume (L) = Duration (mins) × Impeller Flow Rate (8.0 L/min)',
      variables: [
        MathVariable(
          label: 'Commute Duration',
          value: session.duration.inMinutes > 0
              ? '${session.duration.inMinutes} mins'
              : '${session.duration.inSeconds} seconds',
          description: 'Total active blower operation time',
        ),
        MathVariable(
          label: 'Centrifugal Flow Rate',
          value: '8.0 Liters/min',
          description: 'Positive pressure air delivery rating',
        ),
      ],
      calculationStep: session.duration.inMinutes > 0
          ? '${session.duration.inMinutes} mins × 8.0 L/min = ~${session.cleanAirVolumeLiters} Liters'
          : '${session.duration.inSeconds}s (0.4 min) × 8.0 L/min = ~${session.cleanAirVolumeLiters} Liters',
      result: '~${session.cleanAirVolumeLiters} Liters of Clean Air Delivered',
      standard: 'Human Resting Inhalation Minute Volume (6–8 L/min)',
    );
  }
}
