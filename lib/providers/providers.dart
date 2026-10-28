import 'package:flutter_riverpod/flutter_riverpod.dart';

// ── Theme Provider ──────────────────────────────────────────
final isDarkModeProvider = StateProvider<bool>((ref) => true);

// ── Global App Feedback / Snackbars ─────────────────────────
final appNoticeProvider = StateProvider<String?>((ref) => null);
