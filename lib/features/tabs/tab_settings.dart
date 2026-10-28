import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/auth/auth_service.dart';
import '../../core/firebase/firebase_service.dart';
import '../../core/theme/colors.dart';
import '../../providers/auth_provider.dart';
import '../../providers/bluetooth_provider.dart';
import '../../providers/providers.dart';
import '../auth/google_signin_screen.dart';
import '../bluetooth/bluetooth_monitor_screen.dart';

class TabSettings extends ConsumerStatefulWidget {
  const TabSettings({super.key});

  @override
  ConsumerState<TabSettings> createState() => _TabSettingsState();
}

class _TabSettingsState extends ConsumerState<TabSettings> {
  Map<Permission, PermissionStatus> _permissions = {
    Permission.bluetoothConnect: PermissionStatus.denied,
    Permission.bluetoothScan: PermissionStatus.denied,
    Permission.locationWhenInUse: PermissionStatus.denied,
    Permission.notification: PermissionStatus.denied,
  };

  bool _isCheckingPermissions = false;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    setState(() => _isCheckingPermissions = true);
    final Map<Permission, PermissionStatus> results = {};
    for (final p in [
      Permission.bluetoothConnect,
      Permission.bluetoothScan,
      Permission.locationWhenInUse,
      Permission.notification,
    ]) {
      try {
        results[p] = await p.status;
      } catch (_) {
        results[p] = PermissionStatus.denied;
      }
    }
    if (mounted) {
      setState(() {
        _permissions = results;
        _isCheckingPermissions = false;
      });
    }
  }

  Future<void> _requestPermission(Permission p) async {
    try {
      final status = await p.request();
      if (mounted) {
        setState(() => _permissions[p] = status);
      }
    } catch (e) {
      debugPrint('Error requesting $p: $e');
    }
  }

  Future<void> _requestAllPermissions() async {
    try {
      final list = [
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.locationWhenInUse,
        Permission.notification,
      ];
      await list.request();
      await _checkPermissions();
    } catch (e) {
      debugPrint('Error requesting all permissions: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final btService = ref.watch(bluetoothServiceProvider);
    final isConnected = btService.isConnected;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        children: [
          // Section Header
          Row(
            children: [
              Text(
                'SETTINGS & SYSTEM',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                ),
              ),
            ],
          ),
          const Gap(12),

          // ==========================================
          // 1. PROFILE / GOOGLE ACCOUNT CARD
          // ==========================================
          _buildProfileCard(context, ref, isDark, user),

          const Gap(16),

          // ==========================================
          // 2. TERMINAL & HARDWARE DIAGNOSTICS
          // ==========================================
          _buildTerminalCard(context, ref, isDark, btService, isConnected),

          const Gap(16),

          // ==========================================
          // 3. ANDROID SYSTEM PERMISSIONS
          // ==========================================
          _buildPermissionsCard(context, isDark),

          const Gap(16),

          // ==========================================
          // 4. PREFERENCES & CLOUD SYNC
          // ==========================================
          _buildPreferencesCard(context, ref, isDark),

          const Gap(24),

          // App build footer
          Center(
            child: Text(
              'Pure Helmet OS • Build v1.0.0+1 (2026.10)\nEngineered for Smart Air Purification',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
                height: 1.5,
              ),
            ),
          ),
          const Gap(16),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PROFILE CARD
  // ---------------------------------------------------------------------------
  Widget _buildProfileCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    dynamic user,
  ) {
    final bool isSignedIn = user != null;
    final String displayName = isSignedIn ? (user.displayName ?? 'Rider') : 'Guest Rider';
    final String email = isSignedIn ? (user.email ?? 'Connected via Google') : 'Local Mode • Cloud sync paused';
    final String? photoUrl = isSignedIn ? user.photoURL : null;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? PureColors.darkSurfaceElevated : PureColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: PureColors.primaryTeal.withOpacity(0.5),
                    width: 2,
                  ),
                  color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                ),
                child: ClipOval(
                  child: photoUrl != null
                      ? Image.network(
                          photoUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildAvatarFallback(displayName),
                        )
                      : _buildAvatarFallback(displayName),
                ),
              ),
              const Gap(14),
              // User Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            displayName,
                            style: GoogleFonts.sora(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Gap(6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isSignedIn
                                ? PureColors.primaryTeal.withOpacity(0.15)
                                : Colors.amber.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isSignedIn ? 'GOOGLE' : 'GUEST',
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: isSignedIn ? PureColors.primaryTeal : Colors.amber,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(3),
                    Text(
                      email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(16),
          const Divider(height: 1, color: Colors.white10),
          const Gap(14),
          // Action button
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isSignedIn ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                    size: 16,
                    color: isSignedIn ? PureColors.primaryTeal : Colors.grey,
                  ),
                  const Gap(6),
                  Text(
                    isSignedIn ? 'Cloud Sync Active' : 'Sign in to sync ride history',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
              if (isSignedIn)
                OutlinedButton.icon(
                  onPressed: () async {
                    await AuthService.instance.signOut();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Signed out of Google account'),
                          backgroundColor: Colors.black87,
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 14, color: Colors.redAccent),
                  label: Text(
                    'Sign Out',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.redAccent,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.redAccent.withOpacity(0.4)),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                )
              else
                FilledButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const GoogleSignInScreen()),
                    );
                  },
                  icon: const Icon(Icons.login_rounded, size: 14, color: Colors.black),
                  label: Text(
                    'Sign In',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: PureColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvatarFallback(String name) {
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'P';
    return Center(
      child: Text(
        initials,
        style: GoogleFonts.sora(
          fontSize: 22,
          fontWeight: FontWeight.w700,
          color: PureColors.primaryTeal,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TERMINAL & HARDWARE DIAGNOSTICS CARD
  // ---------------------------------------------------------------------------
  Widget _buildTerminalCard(
    BuildContext context,
    WidgetRef ref,
    bool isDark,
    dynamic btService,
    bool isConnected,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? PureColors.darkSurfaceElevated : PureColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isConnected
              ? PureColors.primaryTeal.withOpacity(0.35)
              : (isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: PureColors.primaryTeal.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.terminal_rounded,
                        size: 20,
                        color: PureColors.primaryTeal,
                      ),
                    ),
                    const Gap(10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ESP32 Terminal',
                            style: GoogleFonts.sora(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Serial telemetry & packet console',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(8),
              // Pulse status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (isConnected ? PureColors.primaryTeal : Colors.grey).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (isConnected ? PureColors.primaryTeal : Colors.grey).withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isConnected ? PureColors.primaryTeal : Colors.grey,
                      ),
                    ),
                    const Gap(5),
                    Text(
                      isConnected ? 'LIVE' : 'OFFLINE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: isConnected ? PureColors.primaryTeal : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(14),
          // Terminal Info Box
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0C141B) : const Color(0xFFE8EEF2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? Colors.white10 : Colors.black12,
              ),
            ),
            child: Column(
              children: [
                _buildDiagnosticRow(
                  label: 'Hardware Name',
                  value: btService.connectedDevice?.name ?? 'ESP32_BME680_Full',
                  isDark: isDark,
                ),
                const Gap(6),
                _buildDiagnosticRow(
                  label: 'Device MAC',
                  value: btService.connectedDevice?.address ?? 'F4:2D:C9:89:D7:02',
                  isDark: isDark,
                ),
                const Gap(6),
                _buildDiagnosticRow(
                  label: 'Protocol / Baud',
                  value: 'RFCOMM SPP • 115200 bps',
                  isDark: isDark,
                ),
              ],
            ),
          ),
          const Gap(14),
          // Open Terminal Button
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const BluetoothMonitorScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.code_rounded, size: 18),
              label: Text(
                'Open Serial Terminal & Packets',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: isDark ? PureColors.darkSurface : const Color(0xFF16222C),
                foregroundColor: PureColors.primaryTeal,
                side: BorderSide(color: PureColors.primaryTeal.withOpacity(0.35)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDiagnosticRow({
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // ANDROID PERMISSIONS CARD
  // ---------------------------------------------------------------------------
  Widget _buildPermissionsCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? PureColors.darkSurfaceElevated : PureColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: PureColors.secondaryBlue.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.security_rounded,
                      size: 20,
                      color: PureColors.secondaryBlue,
                    ),
                  ),
                  const Gap(10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Android Permissions',
                        style: GoogleFonts.sora(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        'Hardware & background privileges',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              IconButton(
                tooltip: 'Refresh Status',
                icon: _isCheckingPermissions
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: PureColors.primaryTeal),
                      )
                    : const Icon(Icons.refresh_rounded, size: 18),
                onPressed: _checkPermissions,
              ),
            ],
          ),
          const Gap(14),

          // 1. Bluetooth Connect
          _buildPermissionItem(
            permission: Permission.bluetoothConnect,
            icon: Icons.bluetooth_connected_rounded,
            title: 'Bluetooth Connect',
            subtitle: 'Stream live telemetry & send fan controls',
            isDark: isDark,
          ),
          const Divider(height: 16, color: Colors.white10),

          // 2. Bluetooth Scan
          _buildPermissionItem(
            permission: Permission.bluetoothScan,
            icon: Icons.bluetooth_searching_rounded,
            title: 'Bluetooth Scan',
            subtitle: 'Scan & discover Pure Helmet devices',
            isDark: isDark,
          ),
          const Divider(height: 16, color: Colors.white10),

          // 3. Location / GPS
          _buildPermissionItem(
            permission: Permission.locationWhenInUse,
            icon: Icons.location_on_rounded,
            title: 'GPS Location',
            subtitle: 'Fetch ambient outside AQI & temperature',
            isDark: isDark,
          ),
          const Divider(height: 16, color: Colors.white10),

          // 4. Notifications
          _buildPermissionItem(
            permission: Permission.notification,
            icon: Icons.notifications_active_rounded,
            title: 'System Notifications',
            subtitle: 'Helmet fog alerts & toxic air warnings',
            isDark: isDark,
          ),
          const Gap(16),

          // Actions Row
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _requestAllPermissions,
                  icon: const Icon(Icons.verified_user_rounded, size: 15),
                  label: Text(
                    'Grant All',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: PureColors.primaryTeal),
                    foregroundColor: PureColors.primaryTeal,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const Gap(10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => openAppSettings(),
                  icon: const Icon(Icons.app_settings_alt_rounded, size: 15),
                  label: Text(
                    'App Settings',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: isDark ? Colors.white12 : Colors.black12,
                    foregroundColor: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionItem({
    required Permission permission,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    final status = _permissions[permission] ?? PermissionStatus.denied;
    final bool isGranted = status.isGranted;

    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: isGranted ? PureColors.primaryTeal : Colors.grey,
        ),
        const Gap(12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                ),
              ),
              Text(
                subtitle,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                ),
              ),
            ],
          ),
        ),
        InkWell(
          onTap: isGranted ? null : () => _requestPermission(permission),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isGranted
                  ? PureColors.primaryTeal.withOpacity(0.15)
                  : Colors.orangeAccent.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isGranted
                    ? PureColors.primaryTeal.withOpacity(0.35)
                    : Colors.orangeAccent.withOpacity(0.35),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  isGranted ? Icons.check_circle_rounded : Icons.lock_open_rounded,
                  size: 13,
                  color: isGranted ? PureColors.primaryTeal : Colors.orangeAccent,
                ),
                const Gap(4),
                Text(
                  isGranted ? 'Allowed' : 'Grant',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: isGranted ? PureColors.primaryTeal : Colors.orangeAccent,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // PREFERENCES & CLOUD SYNC CARD
  // ---------------------------------------------------------------------------
  Widget _buildPreferencesCard(BuildContext context, WidgetRef ref, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? PureColors.darkSurfaceElevated : PureColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? PureColors.darkCardBorder : PureColors.lightCardBorder,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'PREFERENCES & SYNC',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: isDark ? PureColors.textMuted : PureColors.lightTextMuted,
            ),
          ),
          const Gap(12),

          // Theme Switch
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    color: PureColors.primaryTeal,
                    size: 20,
                  ),
                  const Gap(12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance Theme',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        isDark ? 'Dark CleanTech mode' : 'Light CleanTech mode',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Switch(
                value: isDark,
                activeColor: PureColors.primaryTeal,
                onChanged: (val) {
                  ref.read(isDarkModeProvider.notifier).state = val;
                },
              ),
            ],
          ),
          const Divider(height: 16, color: Colors.white10),

          // Firebase Firestore
          Row(
            children: [
              const Icon(
                Icons.cloud_sync_rounded,
                color: PureColors.secondaryBlue,
                size: 20,
              ),
              const Gap(12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Firebase Firestore Sync',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      FirebaseService.instance.statusMessage,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Gap(14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () async {
                final user = ref.read(currentUserProvider);
                final success = await FirebaseService.instance.initializeAllFirestoreTables(
                  customUid: user?.uid,
                  customEmail: user?.email,
                );
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          Icon(
                            success ? Icons.cloud_done_rounded : Icons.cloud_off_rounded,
                            color: success ? PureColors.primaryTeal : Colors.redAccent,
                            size: 18,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              success
                                  ? 'All 7 Firestore Collections created & synced to helmet-747e8!'
                                  : 'Could not reach Firestore. Check device internet / rules.',
                              style: GoogleFonts.inter(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      backgroundColor: const Color(0xFF1E293B),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.storage_rounded, size: 16),
              label: Text(
                'Sync & Create Firestore Tables',
                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: PureColors.primaryTeal.withOpacity(0.5)),
                foregroundColor: PureColors.primaryTeal,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
