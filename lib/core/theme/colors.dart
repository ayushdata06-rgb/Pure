import 'dart:ui';

import 'package:flutter/material.dart';

/// Pure app color palette – CleanTech + Smart PPE aesthetic
class PureColors {
  PureColors._();

  // ── Dark theme ──────────────────────────────────────────────
  static const Color darkBackground = Color(0xFF0A0F14);
  static const Color darkSurface = Color(0xFF111A22);
  static const Color darkSurfaceElevated = Color(0xFF16222C);
  static const Color darkCardBorder = Color(0x991F2E3A); // 60% opacity

  // ── Light theme ─────────────────────────────────────────────
  static const Color lightBackground = Color(0xFFF4F8FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceElevated = Color(0xFFF0F4F7);
  static const Color lightCardBorder = Color(0x1A1F2E3A);

  // ── Brand accents ───────────────────────────────────────────
  static const Color primaryTeal = Color(0xFF19E6C1);
  static const Color secondaryBlue = Color(0xFF3B9DFF);

  // ── Text (dark theme) ───────────────────────────────────────
  static const Color textPrimary = Color(0xFFF2F7FA);
  static const Color textSecondary = Color(0xFF8CA0AE);
  static const Color textMuted = Color(0xFF5A6B78);

  // ── Text (light theme) ─────────────────────────────────────
  static const Color lightTextPrimary = Color(0xFF0A0F14);
  static const Color lightTextSecondary = Color(0xFF5A6B78);
  static const Color lightTextMuted = Color(0xFF8CA0AE);

  // ── AQI states ──────────────────────────────────────────────
  static const Color aqiGood = Color(0xFF2EE59D);
  static const Color aqiModerate = Color(0xFFFFC53D);
  static const Color aqiPoor = Color(0xFFFF8A3D);
  static const Color aqiVeryPoor = Color(0xFFFF4D5E);

  // ── Gradients ───────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryTeal, secondaryBlue],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const RadialGradient tealGlow = RadialGradient(
    colors: [Color(0x3019E6C1), Color(0x0019E6C1)],
    radius: 0.8,
  );

  /// Returns the AQI color for a given PM2.5 value (µg/m³)
  static Color aqiColor(double pm25) {
    if (pm25 <= 12) return aqiGood;
    if (pm25 <= 35) return aqiModerate;
    if (pm25 <= 55) return aqiPoor;
    return aqiVeryPoor;
  }

  /// Returns the AQI label
  static String aqiLabel(double pm25) {
    if (pm25 <= 12) return 'Good';
    if (pm25 <= 35) return 'Moderate';
    if (pm25 <= 55) return 'Poor';
    return 'Very Poor';
  }

  /// Returns health guidance text
  static String aqiAdvice(double pm25) {
    if (pm25 <= 12) return 'Air quality is satisfactory. Enjoy your ride!';
    if (pm25 <= 35) {
      return 'Sensitive groups should limit prolonged outdoor exposure.';
    }
    if (pm25 <= 55) return 'Everyone may experience health effects. Use purification.';
    return 'Health alert! Avoid outdoor activity without full purification.';
  }
}
