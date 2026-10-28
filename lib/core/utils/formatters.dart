import 'package:intl/intl.dart';

/// Formatting helpers
class Formatters {
  Formatters._();

  static String pm25(double value) => value.toStringAsFixed(0);

  static String percentage(double value) => '${value.toStringAsFixed(0)}%';

  static String duration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  static String batteryTime(double batteryPercent) {
    final hours = (batteryPercent / 100 * 7.2).clamp(0, 99);
    final h = hours.floor();
    final m = ((hours - h) * 60).round();
    return '≈ ${h}h ${m}m left';
  }

  static String filterTime(double filterPercent) {
    final hours = (filterPercent / 100 * 54).round();
    return '~${hours} hrs left';
  }

  static String time(DateTime dt) => DateFormat('HH:mm').format(dt);

  static String dateShort(DateTime dt) => DateFormat('MMM d').format(dt);

  static String dayOfWeek(DateTime dt) => DateFormat('EEE').format(dt);

  static String dateRange(DateTime start, DateTime end) =>
      '${DateFormat('MMM d').format(start)} – ${DateFormat('MMM d').format(end)}';
}
