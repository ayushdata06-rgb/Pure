import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Pure app typography – Sora for headings/metrics, Inter for body
class PureTypography {
  PureTypography._();

  // ── Headings / metrics (Sora) ──────────────────────────────
  static TextStyle bigMetric(Color color) => GoogleFonts.sora(
    fontSize: 56,
    fontWeight: FontWeight.w700,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );

  static TextStyle metric48(Color color) => GoogleFonts.sora(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.1,
  );

  static TextStyle metric32(Color color) => GoogleFonts.sora(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.2,
  );

  static TextStyle metric24(Color color) => GoogleFonts.sora(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: color,
    fontFeatures: const [FontFeature.tabularFigures()],
    height: 1.2,
  );

  static TextStyle sectionTitle(Color color) => GoogleFonts.sora(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.3,
  );

  static TextStyle cardTitle(Color color) => GoogleFonts.sora(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.3,
  );

  // ── Body / labels (Inter) ──────────────────────────────────
  static TextStyle body(Color color) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.5,
  );

  static TextStyle bodyMedium(Color color) => GoogleFonts.inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: color,
    height: 1.5,
  );

  static TextStyle label(Color color) => GoogleFonts.inter(
    fontSize: 13,
    fontWeight: FontWeight.w500,
    color: color,
    height: 1.4,
    letterSpacing: 0.2,
  );

  static TextStyle caption(Color color) => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: color,
    height: 1.4,
    letterSpacing: 0.4,
  );

  static TextStyle buttonText(Color color) => GoogleFonts.inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: color,
    height: 1.0,
    letterSpacing: 0.3,
  );

  static TextStyle tabularNumber(Color color, {double fontSize = 16}) =>
      GoogleFonts.sora(
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        color: color,
        fontFeatures: const [FontFeature.tabularFigures()],
      );
}
