import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme/app_theme.dart';
import 'providers/providers.dart';
import 'features/splash/splash_screen.dart';

class PureApp extends ConsumerWidget {
  const PureApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = ref.watch(isDarkModeProvider);

    return MaterialApp(
      title: 'Pure – Air Purifying Helmet',
      debugShowCheckedModeBanner: false,
      theme: PureTheme.light(),
      darkTheme: PureTheme.dark(),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const SplashScreen(),
    );
  }
}
