import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/colors.dart';
import '../../providers/bluetooth_provider.dart';
import '../tabs/tab_home.dart';
import '../tabs/tab_info.dart';
import '../tabs/tab_history.dart';
import '../tabs/tab_settings.dart';
import '../../providers/outdoor_provider.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _tabs = const [
    TabHome(),
    TabInfo(),
    TabHistory(),
    TabSettings(),
  ];

  @override
  Widget build(BuildContext context) {
    final btService = ref.watch(bluetoothServiceProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isConnected = btService.isConnected;

    return Scaffold(
      backgroundColor: isDark ? PureColors.darkBackground : PureColors.lightBackground,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Pure Leaf Logo Emblem
                Container(
                  width: 28,
                  height: 28,
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: PureColors.primaryTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: PureColors.primaryTeal.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.eco_rounded,
                      color: PureColors.primaryTeal,
                      size: 18,
                    ),
                  ),
                ),
                // App Title
                Text(
                  'Pure',
                  style: GoogleFonts.sora(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? PureColors.textPrimary : PureColors.lightTextPrimary,
                  ),
                ),
                const Gap(8),
                // ESP32 Status Pill
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
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isConnected ? PureColors.primaryTeal : Colors.grey,
                        ),
                      ),
                      const Gap(5),
                      Text(
                        isConnected ? 'ESP32 Live' : 'Offline',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: isConnected ? PureColors.primaryTeal : Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // GPS Location Pill
                Consumer(
                  builder: (context, ref, _) {
                    final outdoor = ref.watch(outdoorDataProvider);
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.04),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isDark ? Colors.white12 : Colors.black12,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.location_on_rounded, size: 13, color: PureColors.primaryTeal),
                          const Gap(4),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 120),
                            child: Text(
                              outdoor.cityName,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: isDark ? PureColors.textSecondary : PureColors.lightTextSecondary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (idx) => setState(() => _currentIndex = idx),
        backgroundColor: isDark ? PureColors.darkSurface : PureColors.lightSurface,
        indicatorColor: PureColors.primaryTeal.withOpacity(0.2),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard_rounded, color: PureColors.primaryTeal),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.insights_outlined),
            selectedIcon: Icon(Icons.insights_rounded, color: PureColors.primaryTeal),
            label: 'Info',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded, color: PureColors.primaryTeal),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded, color: PureColors.primaryTeal),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

