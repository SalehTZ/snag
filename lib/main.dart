import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:window_manager/window_manager.dart';

import 'app.dart';
import 'core/app_info.dart';
import 'data/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  LicenseRegistry.addLicense(() async* {
    for (final font in ['Figtree', 'Vazirmatn']) {
      final ofl = await rootBundle.loadString('assets/fonts/$font-OFL.txt');
      yield LicenseEntryWithLineBreaks([font], ofl);
    }
  });

  if (isDesktop) {
    await windowManager.ensureInitialized();
    await windowManager.waitUntilReadyToShow(
      const WindowOptions(
        title: AppInfo.name,
        size: Size(1080, 760),
        minimumSize: Size(400, 560),
        center: true,
      ),
      () async {
        await windowManager.show();
        await windowManager.focus();
      },
    );
  }

  final bootstrap = await Bootstrap.load();
  runApp(ProviderScope(
    overrides: [bootstrapProvider.overrideWithValue(bootstrap)],
    child: const SnagApp(),
  ));
}
