import '../theme/colors.dart';
import 'package:flutter/material.dart';

/// AQI category utilities
class AqiUtils {
  AqiUtils._();

  static Color color(double pm25) => PureColors.aqiColor(pm25);
  static String label(double pm25) => PureColors.aqiLabel(pm25);
  static String advice(double pm25) => PureColors.aqiAdvice(pm25);

  /// Returns the fractional position (0–1) on the AQI scale bar
  static double scalePosition(double pm25) {
    if (pm25 <= 0) return 0;
    if (pm25 >= 80) return 1;
    return pm25 / 80;
  }
}
