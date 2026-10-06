import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_info.dart';
import 'core/theme/theme.dart';
import 'data/providers.dart';
import 'features/setup/setup_screen.dart';
import 'l10n/l10n.dart';
import 'shell.dart';

class SnagApp extends ConsumerStatefulWidget {
  const SnagApp({super.key});

  @override
  ConsumerState<SnagApp> createState() => _SnagAppState();
}

class _SnagAppState extends ConsumerState<SnagApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  // Re-resolve "System default" when the OS language changes.
  @override
  void didChangeLocales(List<Locale>? locales) => setState(() {});

  /// The chosen language, or the best match for the device's languages.
  Locale _resolveLocale(String? code) {
    final saved = savedLocale(code);
    if (saved != null) return saved;
    return basicLocaleListResolution(
      WidgetsBinding.instance.platformDispatcher.locales,
      AppLocalizations.supportedLocales,
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final accent = ref.watch(bootstrapProvider).systemAccent;
    final locale = _resolveLocale(settings.localeCode);
    final cursive = isCursiveScript(locale);
    // Wallpaper/accent color when allowed, else the user's chosen seed.
    final seed = settings.dynamicColor && accent != null
        ? accent
        : Color(settings.seedColor);
    return MaterialApp(
      title: AppInfo.name,
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      themeMode: settings.themeMode,
      theme: AppTheme.build(AppTheme.schemeFromSeed(seed, Brightness.light),
          cursive: cursive),
      darkTheme: AppTheme.build(AppTheme.schemeFromSeed(seed, Brightness.dark),
          cursive: cursive),
      home: settings.setupDone ? const AppShell() : const SetupScreen(),
    );
  }
}
