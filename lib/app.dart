import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_info.dart';
import 'core/theme/theme.dart';
import 'data/providers.dart';
import 'features/setup/setup_screen.dart';
import 'shell.dart';

class SnagApp extends ConsumerWidget {
  const SnagApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final accent = ref.watch(bootstrapProvider).systemAccent;
    // Wallpaper/accent color when allowed, else the user's chosen seed.
    final seed = settings.dynamicColor && accent != null
        ? accent
        : Color(settings.seedColor);
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.build(AppTheme.schemeFromSeed(seed, Brightness.light)),
      darkTheme: AppTheme.build(AppTheme.schemeFromSeed(seed, Brightness.dark)),
      home: isDesktop && !settings.setupDone
          ? const SetupScreen()
          : const AppShell(),
    );
  }
}
