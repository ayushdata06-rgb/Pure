import 'dart:ui';
import 'package:flutter/material.dart';
import '../core/theme/colors.dart';
import '../core/theme/app_theme.dart';

/// Glassmorphic card used throughout Pure.
class PureCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Gradient? gradient;
  final Color? borderColor;

  const PureCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.gradient,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface =
        isDark ? PureColors.darkSurface : PureColors.lightSurface;
    final border =
        borderColor ?? (isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder);

    Widget card = Container(
      decoration: BoxDecoration(
        color: gradient == null ? surface : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(PureTheme.cardRadius),
        border: Border.all(color: border),
      ),
      padding: padding ??
          const EdgeInsets.all(PureTheme.cardPadding),
      child: child,
    );

    if (onTap != null) {
      card = Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(PureTheme.cardRadius),
          onTap: onTap,
          child: card,
        ),
      );
    }

    return card;
  }
}
