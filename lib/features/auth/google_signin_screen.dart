import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/auth/auth_service.dart';
import '../../core/firebase/firebase_service.dart';
import '../../core/theme/colors.dart';
import '../../providers/auth_provider.dart';
import '../shell/main_shell.dart';

class GoogleSignInScreen extends ConsumerStatefulWidget {
  const GoogleSignInScreen({super.key});

  @override
  ConsumerState<GoogleSignInScreen> createState() => _GoogleSignInScreenState();
}

class _GoogleSignInScreenState extends ConsumerState<GoogleSignInScreen> {
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final credential = await AuthService.instance.signInWithGoogle();
      if (!mounted) return;

      if (credential != null && credential.user != null) {
        // Successfully signed in, navigate to MainShell
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainShell()),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        if (!FirebaseService.instance.isInitialized) {
          _errorMessage =
              'Firebase pending setup: Please add google-services.json to android/app to complete Google OAuth.';
        } else {
          _errorMessage = 'Sign-in failed: ${e.toString()}';
        }
      });
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _continueAsGuest() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? PureColors.darkBackground : PureColors.lightBackground,
      body: Stack(
        children: [
          // Ambient Glow Background
          Positioned(
            top: -60,
            left: -60,
            child: Container(
              width: 320,
              height: 320,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: PureColors.tealGlow,
              ),
            ),
          ),

          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Brand Icon
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: PureColors.primaryGradient,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: PureColors.primaryTeal.withOpacity(0.35),
                            blurRadius: 28,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.eco_rounded,
                          size: 44,
                          color: Colors.black,
                        ),
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.easeOutBack),

                    const Gap(24),

                    // Title
                    Text(
                      'Pure Helmet',
                      style: GoogleFonts.sora(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                      ),
                    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.2),

                    const Gap(8),

                    Text(
                      'Smart Air-Purifying Helmet & Telemetry',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 100.ms),

                    const Gap(36),

                    // Feature highlights container
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      decoration: BoxDecoration(
                        color: isDark ? PureColors.darkSurface : PureColors.lightSurface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder,
                        ),
                      ),
                      child: Column(
                        children: [
                          _buildFeatureRow(
                            Icons.sensors_rounded,
                            'Live BME680 Sensor Sync',
                            'Real-time temperature, VOCs, humidity & altitude',
                            isDark,
                          ),
                          const Divider(height: 20),
                          _buildFeatureRow(
                            Icons.cloud_sync_rounded,
                            'Firebase Cloud Telemetry',
                            'Automated cloud storage for ride diagnostics',
                            isDark,
                          ),
                          const Divider(height: 20),
                          _buildFeatureRow(
                            Icons.security_rounded,
                            'Secure Google OAuth',
                            'Single sign-on protection across all devices',
                            isDark,
                          ),
                        ],
                      ),
                    ).animate().fadeIn(duration: 400.ms, delay: 200.ms).slideY(begin: 0.1),

                    const Gap(32),

                    // Error Banner if any
                    if (_errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.redAccent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.redAccent, size: 20),
                            const Gap(10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: GoogleFonts.inter(fontSize: 12, color: Colors.redAccent),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(20),
                    ],

                    // Signed in state vs Google Sign-In Button
                    if (user != null) ...[
                      // User already signed in
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: PureColors.primaryTeal.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: PureColors.primaryTeal.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 22,
                              backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                              child: user.photoURL == null
                                  ? Text(user.displayName?[0] ?? 'U')
                                  : null,
                            ),
                            const Gap(12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.displayName ?? 'Signed in User',
                                    style: GoogleFonts.sora(fontSize: 14, fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    user.email ?? '',
                                    style: GoogleFonts.inter(fontSize: 12, color: PureColors.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Gap(16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PureColors.primaryTeal,
                          foregroundColor: Colors.black,
                          minimumSize: const Size.fromHeight(52),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _continueAsGuest,
                        child: Text(
                          'Continue to Dashboard',
                          style: GoogleFonts.sora(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Gap(10),
                      TextButton(
                        onPressed: () => AuthService.instance.signOut(),
                        child: const Text('Sign Out'),
                      ),
                    ] else ...[
                      // Google Sign-In Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.black87,
                            elevation: 2,
                            shadowColor: Colors.black26,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: const BorderSide(color: Color(0xFFE2E8F0)),
                            ),
                          ),
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(strokeWidth: 2.5),
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _buildGoogleLogo(),
                                    const Gap(12),
                                    Text(
                                      'Continue with Google',
                                      style: GoogleFonts.inter(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1F2937),
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 300.ms).slideY(begin: 0.1),

                      const Gap(20),

                      // Skip / Continue as Guest
                      TextButton(
                        onPressed: _continueAsGuest,
                        child: Text(
                          'Skip for now · Continue as Guest →',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                          ),
                        ),
                      ).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                    ],

                    const Gap(24),

                    // Privacy Note
                    Text(
                      'By continuing, you agree to our Terms of Service\nand Environmental Data Policy.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureRow(IconData icon, String title, String subtitle, bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: PureColors.primaryTeal.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: PureColors.primaryTeal),
        ),
        const Gap(14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.sora(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGoogleLogo() {
    return Image.network(
      'https://upload.wikimedia.org/wikipedia/commons/thumb/c/c1/Google_%22G%22_logo.svg/480px-Google_%22G%22_logo.svg.png',
      width: 22,
      height: 22,
      errorBuilder: (_, __, ___) => const Icon(
        Icons.g_mobiledata_rounded,
        size: 26,
        color: Colors.redAccent,
      ),
    );
  }
}
