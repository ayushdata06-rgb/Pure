import 'package:flutter/material.dart';
import 'colors.dart';

/// Builds Material 3 ThemeData for dark and light modes.
class PureTheme {
  PureTheme._();

  static const double screenPadding = 20;
  static const double cardRadius = 24;
  static const double buttonRadius = 16;
  static const double pillRadius = 999;
  static const double cardGap = 16;
  static const double cardPadding = 16;

  static ThemeData dark() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: PureColors.darkBackground,
    colorScheme: const ColorScheme.dark(
      surface: PureColors.darkSurface,
      primary: PureColors.primaryTeal,
      secondary: PureColors.secondaryBlue,
      onSurface: PureColors.textPrimary,
      onPrimary: PureColors.darkBackground,
    ),
    cardTheme: CardThemeData(
      color: PureColors.darkSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: const BorderSide(color: PureColors.darkCardBorder),
      ),
      margin: EdgeInsets.zero,
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: Colors.transparent,
      selectedItemColor: PureColors.primaryTeal,
      unselectedItemColor: PureColors.textMuted,
    ),
    iconTheme: const IconThemeData(color: PureColors.textSecondary, size: 22),
    dividerColor: PureColors.darkCardBorder,
  );

  static ThemeData light() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: PureColors.lightBackground,
    colorScheme: const ColorScheme.light(
      surface: PureColors.lightSurface,
      primary: PureColors.primaryTeal,
      secondary: PureColors.secondaryBlue,
      onSurface: PureColors.lightTextPrimary,
      onPrimary: Colors.white,
    ),
    cardTheme: CardThemeData(
      color: PureColors.lightSurface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(cardRadius),
        side: const BorderSide(color: PureColors.lightCardBorder),
      ),
      margin: EdgeInsets.zero,
    ),
    iconTheme: const IconThemeData(
      color: PureColors.lightTextSecondary,
      size: 22,
    ),
    dividerColor: PureColors.lightCardBorder,
  );
}
