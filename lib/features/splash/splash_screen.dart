import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_service.dart';
import '../../core/theme/colors.dart';
import '../auth/google_signin_screen.dart';
import '../shell/main_shell.dart';

/// Animated splash screen: "Pure" wordmark with air-flow swoosh.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2200), _navigateToNextScreen);
  }

  void _navigateToNextScreen() {
    if (!mounted) return;
    final user = AuthService.instance.currentUser;
    final destination = user != null ? const MainShell() : const GoogleSignInScreen();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => destination,
        transitionDuration: const Duration(milliseconds: 500),
        transitionsBuilder: (_, anim, __, child) {
          return FadeTransition(opacity: anim, child: child);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: PureColors.darkBackground,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Leaf/wind icon
            Icon(
              Icons.eco_rounded,
              size: 48,
              color: PureColors.primaryTeal,
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .scale(begin: const Offset(0.5, 0.5), curve: Curves.easeOutBack)
                .then(delay: 200.ms)
                .rotate(begin: -0.05, end: 0, duration: 400.ms),

            const SizedBox(height: 16),

            // "Pure" wordmark
            Text(
              'Pure',
              style: GoogleFonts.sora(
                fontSize: 42,
                fontWeight: FontWeight.w700,
                color: PureColors.textPrimary,
                letterSpacing: 2,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms, delay: 300.ms)
                .slideY(begin: 0.2, curve: Curves.easeOutCubic),

            const SizedBox(height: 8),

            // Tagline
            Text(
              'Breathe Clean. Ride Safe.',
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: PureColors.textSecondary,
                letterSpacing: 1,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms, delay: 600.ms)
                .slideY(begin: 0.3, curve: Curves.easeOutCubic),

            const SizedBox(height: 40),

            // Swoosh line
            SizedBox(
              width: 120,
              height: 3,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: PureColors.primaryGradient,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 400.ms, delay: 800.ms)
                .scaleX(begin: 0, alignment: Alignment.centerLeft, curve: Curves.easeOutCubic),
          ],
        ),
      ),
    );
  }
}
