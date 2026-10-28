import 'package:flutter/material.dart';
import '../core/theme/colors.dart';

/// Container with soft teal glow behind child – used for hero elements.
class GlowContainer extends StatelessWidget {
  final Widget child;
  final Color glowColor;
  final double glowRadius;
  final double glowOpacity;

  const GlowContainer({
    super.key,
    required this.child,
    this.glowColor = PureColors.primaryTeal,
    this.glowRadius = 120,
    this.glowOpacity = 0.15,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Container(
          width: glowRadius * 2,
          height: glowRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(
              colors: [
                glowColor.withOpacity(glowOpacity),
                glowColor.withOpacity(0),
              ],
            ),
          ),
        ),
        child,
      ],
    );
  }
}
