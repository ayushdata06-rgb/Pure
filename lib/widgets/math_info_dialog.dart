import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/theme/colors.dart';

/// Single variable entry in the mathematical calculation breakdown
class MathVariable {
  final String label;
  final String value;
  final String? description;

  const MathVariable({
    required this.label,
    required this.value,
    this.description,
  });
}

/// Interactive information button with haptic feedback
class MathInfoButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  final Color? color;
  final EdgeInsetsGeometry padding;

  const MathInfoButton({
    super.key,
    required this.onTap,
    this.size = 14,
    this.color,
    this.padding = const EdgeInsets.all(4),
  });

  @override
  Widget build(BuildContext context) {
    final activeColor = color ?? PureColors.primaryTeal;

    return Semantics(
      button: true,
      label: 'View calculation breakdown',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: padding,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: activeColor.withOpacity(0.12),
                border: Border.all(
                  color: activeColor.withOpacity(0.35),
                  width: 0.8,
                ),
              ),
              child: Icon(
                Icons.info_outline_rounded,
                size: size,
                color: activeColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens an elegant bottom sheet dialog detailing the math equation, live inputs, and output.
void showMathCalculationDialog({
  required BuildContext context,
  required String title,
  required IconData icon,
  required String description,
  required String formula,
  required List<MathVariable> variables,
  required String calculationStep,
  required String result,
  Color? accentColor,
  String? standard,
}) {
  HapticFeedback.lightImpact();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final activeColor = accentColor ?? PureColors.primaryTeal;
  final cardBg = isDark ? const Color(0xFF111A22) : Colors.white;
  final borderCol = isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder;
  final codeBoxBg = isDark ? const Color(0xFF090E13) : const Color(0xFFF1F5F9);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(ctx).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          border: Border.all(color: borderCol, width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.6 : 0.15),
              blurRadius: 32,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top drag notch
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.black12,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),

              Flexible(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(22, 10, 22, 24),
                  shrinkWrap: true,
                  children: [
                    // Header Row: Icon, Title, and Close Button
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: activeColor.withOpacity(0.14),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: activeColor.withOpacity(0.35)),
                          ),
                          child: Icon(icon, color: activeColor, size: 20),
                        ),
                        const Gap(12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'MATHEMATICAL CALCULATION',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.2,
                                  color: activeColor,
                                ),
                              ),
                              const Gap(2),
                              Text(
                                title,
                                style: GoogleFonts.sora(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? PureColors.textPrimary
                                      : PureColors.lightTextPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => Navigator.of(ctx).pop(),
                          color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                          splashRadius: 18,
                        ),
                      ],
                    ),

                    const Gap(14),

                    // Description / Purpose
                    Text(
                      description,
                      style: GoogleFonts.inter(
                        fontSize: 12.5,
                        height: 1.45,
                        color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                      ),
                    ),

                    const Gap(16),

                    // Formula Container
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: codeBoxBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: activeColor.withOpacity(0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.functions_rounded, size: 14, color: activeColor),
                              const Gap(6),
                              Text(
                                'FORMULA',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                  color: activeColor,
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Text(
                            formula,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? const Color(0xFF67E8F9) : const Color(0xFF0891B2),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Gap(16),

                    // Live Variables Breakdown
                    Text(
                      'LIVE TELEMETRY INPUTS',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                      ),
                    ),
                    const Gap(8),
                    Container(
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF16232D) : const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: borderCol),
                      ),
                      child: Column(
                        children: [
                          for (int i = 0; i < variables.length; i++) ...[
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          variables[i].label,
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
                                            color: isDark
                                                ? PureColors.textPrimary
                                                : PureColors.lightTextPrimary,
                                          ),
                                        ),
                                        if (variables[i].description != null) ...[
                                          const Gap(2),
                                          Text(
                                            variables[i].description!,
                                            style: GoogleFonts.inter(
                                              fontSize: 10.5,
                                              color: isDark
                                                  ? PureColors.textMuted
                                                  : PureColors.lightTextMuted,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const Gap(8),
                                  Text(
                                    variables[i].value,
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700,
                                      color: activeColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (i < variables.length - 1)
                              Divider(
                                height: 1,
                                thickness: 1,
                                color: isDark ? Colors.white10 : Colors.black12,
                              ),
                          ],
                        ],
                      ),
                    ),

                    const Gap(16),

                    // Evaluation Step & Result
                    Text(
                      'COMPUTED RESULT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.0,
                        color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                      ),
                    ),
                    const Gap(8),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: activeColor.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: activeColor.withOpacity(0.35)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            calculationStep,
                            style: GoogleFonts.jetBrainsMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                            ),
                          ),
                          const Gap(8),
                          Row(
                            children: [
                              Icon(Icons.check_circle_rounded, size: 16, color: activeColor),
                              const Gap(6),
                              Expanded(
                                child: Text(
                                  result,
                                  style: GoogleFonts.sora(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: activeColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    if (standard != null) ...[
                      const Gap(14),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0E161C) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.verified_rounded,
                              size: 13,
                              color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                            ),
                            const Gap(6),
                            Expanded(
                              child: Text(
                                standard,
                                style: GoogleFonts.inter(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                  color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

