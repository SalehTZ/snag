// ignore_for_file: invalid_use_of_visible_for_testing_member
// Renders every screen with real fonts and fake data into PNGs, for design
// review and the README:
//
//   flutter test tool/screenshots --update-goldens
//
// Output lands in tool/screenshots/goldens/.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snag/core/theme/theme.dart';
import 'package:snag/data/json_store.dart';
import 'package:snag/data/providers.dart';
import 'package:snag/data/records.dart';
import 'package:snag/data/settings.dart';
import 'package:snag/engine/args_builder.dart';
import 'package:snag/engine/binary_manager.dart';
import 'package:snag/engine/models.dart';
import 'package:snag/engine/ytdlp_engine.dart';
import 'package:snag/features/download_sheet/download_sheet.dart';
import 'package:snag/features/queue/download_manager.dart';
import 'package:snag/features/settings/support_card.dart';
import 'package:snag/features/setup/components_controller.dart';
import 'package:snag/features/setup/setup_screen.dart';
import 'package:snag/l10n/l10n.dart';
import 'package:snag/shell.dart';

class FakeEngine extends YtDlpEngine {
  @override
  bool get allowsBrowserCookies => true;
  @override
  Future<ToolPaths> toolPaths(AppSettings settings) async => const ToolPaths();
  @override
  Future<String> defaultDownloadDir() async => '/home/you/Downloads/Snag';
  @override
  Future<String> runToString(List<String> args, AppSettings settings) async => '{}';
  @override
  Stream<String> runLines(List<String> a, AppSettings s, String id) =>
      const Stream.empty();
  @override
  Future<void> cancel(String taskId) async {}
  @override
  Future<String?> version(AppSettings settings) async => '2026.09.30';
  @override
  Future<UpdateResult> update(AppSettings settings) async =>
      const UpdateResult(changed: true, version: '2026.09.30');
}

class FakeQueue extends DownloadManager {
  FakeQueue(this.tasks);
  final List<DownloadTask> tasks;
  @override
  List<DownloadTask> build() => tasks;
}

class FakeComponents extends ComponentsController {
  FakeComponents(this.states);
  final Map<Component, ComponentState> states;
  @override
  Map<Component, ComponentState> build() => states;
}

class TabAt extends TabNotifier {
  TabAt(this.tab);
  final AppTab tab;
  @override
  AppTab build() => tab;
}

final now = DateTime.now();

final history = [
  HistoryItem(
    id: 'h1',
    spec: const DownloadSpec(url: 'https://youtu.be/a', quality: VideoQuality.p1080),
    meta: const MediaMeta(
        title: 'Building a tiny synthesizer from scratch, part 3: filters',
        uploader: 'Signal Path',
        duration: 1342),
    finishedAt: now.subtract(const Duration(minutes: 12)),
    filePath: '/x.mp4',
    fileSize: 412 * 1024 * 1024,
  ),
  HistoryItem(
    id: 'h2',
    spec: const DownloadSpec(
        url: 'https://soundcloud.com/x',
        mode: DownloadMode.audio,
        audioFormat: AudioFormat.mp3),
    meta: const MediaMeta(
        title: 'Late night lo-fi session (live)', uploader: 'Mellow Rooms',
        duration: 3721),
    finishedAt: now.subtract(const Duration(hours: 3)),
    filePath: '/y.mp3',
    fileSize: 88 * 1024 * 1024,
  ),
  HistoryItem(
    id: 'h3',
    spec: const DownloadSpec(url: 'https://vimeo.com/1'),
    meta: const MediaMeta(
        title: 'Aerial footage of the northern coast at golden hour',
        uploader: 'Wide Open Studio',
        duration: 245),
    finishedAt: now.subtract(const Duration(days: 1, hours: 2)),
    filePath: '/z.mp4',
    fileSize: 156 * 1024 * 1024,
  ),
];

final tasks = [
  DownloadTask(
    id: 't1',
    spec: const DownloadSpec(url: 'https://youtu.be/1', quality: VideoQuality.p1080),
    meta: const MediaMeta(
        title: 'The surprisingly deep history of the paperclip', duration: 912),
    createdAt: now,
    status: TaskStatus.running,
    progress: const ProgressUpdate(
        status: 'downloading',
        downloaded: 182 * 1024 * 1024,
        total: 301 * 1024 * 1024,
        speed: 6.4 * 1024 * 1024,
        eta: 19),
  ),
  DownloadTask(
    id: 't2',
    spec: const DownloadSpec(url: 'https://youtu.be/2'),
    meta: const MediaMeta(title: 'Conference keynote 2026, full talk', duration: 3410),
    createdAt: now,
    status: TaskStatus.processing,
    stage: 'Merging video and audio',
  ),
  DownloadTask(
    id: 't3',
    spec: const DownloadSpec(
        url: 'https://youtu.be/3',
        mode: DownloadMode.audio,
        audioFormat: AudioFormat.opus),
    meta: const MediaMeta(title: 'Rainy cafe ambience, 3 hours'),
    createdAt: now,
  ),
  DownloadTask(
    id: 't4',
    spec: const DownloadSpec(url: 'https://youtu.be/4'),
    meta: const MediaMeta(title: 'How bridges stand up', duration: 640),
    createdAt: now,
    status: TaskStatus.failed,
    failure: EngineException(EngineErrorKind.botCheck),
  ),
  DownloadTask(
    id: 't5',
    spec: const DownloadSpec(url: 'https://youtu.be/5'),
    meta: const MediaMeta(title: 'Ten minute pasta, no shortcuts', duration: 602),
    createdAt: now,
    status: TaskStatus.completed,
    filePath: '/p.mp4',
  ),
];

final sampleInfo = MediaInfo(
  url: 'https://www.youtube.com/watch?v=abc',
  title: 'Building a tiny synthesizer from scratch, part 3: filters and envelopes',
  uploader: 'Signal Path',
  duration: 1342,
  extractor: 'Youtube',
  subtitleLangs: const ['de', 'en', 'es', 'fa', 'fr', 'ja'],
  formats: const [
    MediaFormat(id: '313', ext: 'webm', height: 2160, vcodec: 'vp9', acodec: 'none'),
    MediaFormat(id: '137', ext: 'mp4', height: 1080, vcodec: 'avc1', acodec: 'none'),
    MediaFormat(id: '140', ext: 'm4a', vcodec: 'none', acodec: 'mp4a', abr: 129),
  ],
);

Future<void> loadFonts() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final figtree = FontLoader('Figtree');
  final vazir = FontLoader('Vazirmatn');
  for (final w in ['Regular', 'Medium', 'SemiBold', 'Bold', 'ExtraBold']) {
    figtree.addFont(rootBundle.load('assets/fonts/Figtree-$w.ttf'));
    vazir.addFont(rootBundle.load('assets/fonts/Vazirmatn-$w.ttf'));
  }
  await figtree.load();
  await vazir.load();
  // Real devices resolve 'monospace' themselves; the test renderer does not.
  const mono = '/usr/share/fonts/truetype/dejavu/DejaVuSansMono.ttf';
  if (File(mono).existsSync()) {
    await (FontLoader('monospace')
          ..addFont(Future.value(
              ByteData.sublistView(File(mono).readAsBytesSync()))))
        .load();
  }
  final icons = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File(
            '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
        .readAsBytesSync())));
  await icons.load();
}

Future<Bootstrap> bootstrap({bool withHistory = true}) async {
  SharedPreferences.setMockInitialValues({});
  final dir = Directory.systemTemp.createTempSync('snag-shots');
  return Bootstrap(
    prefs: await SharedPreferences.getInstance(),
    historyStore: JsonListStore.at(File('${dir.path}/h.json'),
        decode: HistoryItem.fromJson, encode: (h) => h.toJson()),
    history: withHistory ? history : const [],
    templateStore: JsonListStore.at(File('${dir.path}/t.json'),
        decode: CommandTemplate.fromJson, encode: (t) => t.toJson()),
    templates: CommandTemplate.defaults,
    systemAccent: null,
  );
}

const readyComponents = {
  Component.ytDlp: ComponentState(
      status: ComponentStatus(Component.ytDlp, ComponentSource.managed,
          version: '2026.09.30')),
  Component.ffmpeg: ComponentState(
      status: ComponentStatus(Component.ffmpeg, ComponentSource.system,
          version: '8.0.1')),
  Component.deno: ComponentState(
      busy: true, progress: 0.62, stage: InstallStage.downloading,
      status: ComponentStatus(Component.deno, ComponentSource.missing)),
};

Future<void> shoot(
  WidgetTester tester,
  String name,
  Widget home, {
  required Size size,
  double dpr = 1.5,
  Brightness brightness = Brightness.light,
  List overrides = const [],
  bool withHistory = true,
  Locale locale = const Locale('en'),
  Future<void> Function(WidgetTester)? before,
}) async {
  tester.view.physicalSize = size * dpr;
  tester.view.devicePixelRatio = dpr;
  final boot = await tester.runAsync(() => bootstrap(withHistory: withHistory));
  final seed = const Color(0xFF6750A4);
  await tester.pumpWidget(ProviderScope(
    key: UniqueKey(),
    overrides: [
      bootstrapProvider.overrideWithValue(boot!),
      engineProvider.overrideWithValue(FakeEngine()),
      componentsProvider.overrideWith(() => FakeComponents(readyComponents)),
      ...overrides,
    ],
    child: MaterialApp(
      debugShowCheckedModeBanner: false,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.build(AppTheme.schemeFromSeed(seed, brightness),
          cursive: isCursiveScript(locale)),
      home: home,
    ),
  ));
  if (before != null) await before(tester);
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 300));
  }
  await expectLater(find.byType(MaterialApp), matchesGoldenFile('goldens/$name.png'));
}

void main() {
  const desktop = Size(1200, 800);
  const phone = Size(412, 892);

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    await loadFonts();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.getData') {
        return {'text': 'https://www.youtube.com/watch?v=dQw4w9WgXcQ'};
      }
      return null;
    });
  });

  for (final b in Brightness.values) {
    final tag = b.name;
    testWidgets('home $tag', (t) async {
      await shoot(t, 'home_desktop_$tag', const AppShell(), size: desktop, brightness: b);
      await shoot(t, 'home_phone_$tag', const AppShell(), size: phone, dpr: 2.5, brightness: b);
    });

    testWidgets('queue $tag', (t) async {
      final o = [
        tabProvider.overrideWith(() => TabAt(AppTab.queue)),
        downloadManagerProvider.overrideWith(() => FakeQueue(tasks)),
      ];
      await shoot(t, 'queue_desktop_$tag', const AppShell(), size: desktop, brightness: b, overrides: o);
      await shoot(t, 'queue_phone_$tag', const AppShell(), size: phone, dpr: 2.5, brightness: b, overrides: o);
    });

    testWidgets('library $tag', (t) async {
      final o = [tabProvider.overrideWith(() => TabAt(AppTab.library))];
      await shoot(t, 'library_desktop_$tag', const AppShell(), size: desktop, brightness: b, overrides: o);
      await shoot(t, 'library_empty_phone_$tag', const AppShell(),
          size: phone, dpr: 2.5, brightness: b, overrides: o, withHistory: false);
    });

    testWidgets('settings $tag', (t) async {
      final o = [tabProvider.overrideWith(() => TabAt(AppTab.settings))];
      await shoot(t, 'settings_desktop_$tag', const AppShell(), size: const Size(1200, 1600), brightness: b, overrides: o);
    });

    testWidgets('sheet $tag', (t) async {
      await shoot(
        t,
        'sheet_phone_$tag',
        Scaffold(body: DownloadSheet(info: sampleInfo)),
        size: phone,
        dpr: 2.5,
        brightness: b,
      );
    });

    testWidgets('setup $tag', (t) async {
      await shoot(t, 'setup_desktop_$tag', const SetupScreen(), size: desktop, brightness: b);
    });
  }

  // Persian: right-to-left layout, Vazirmatn, Persian digits, Jalali dates.
  const fa = Locale('fa');
  testWidgets('farsi', (t) async {
    await shoot(t, 'fa_home_phone', const AppShell(),
        size: phone, dpr: 2.5, locale: fa);
    await shoot(t, 'fa_home_desktop_dark', const AppShell(),
        size: desktop, brightness: Brightness.dark, locale: fa);
    await shoot(t, 'fa_queue_phone', const AppShell(),
        size: phone, dpr: 2.5, locale: fa, overrides: [
      tabProvider.overrideWith(() => TabAt(AppTab.queue)),
      downloadManagerProvider.overrideWith(() => FakeQueue(tasks)),
    ]);
    await shoot(t, 'fa_library_phone', const AppShell(),
        size: phone, dpr: 2.5, locale: fa,
        overrides: [tabProvider.overrideWith(() => TabAt(AppTab.library))]);
    await shoot(t, 'fa_sheet_phone', Scaffold(body: DownloadSheet(info: sampleInfo)),
        size: phone, dpr: 2.5, locale: fa);
    await shoot(t, 'fa_settings_phone', const AppShell(),
        size: const Size(412, 1800), dpr: 2, locale: fa,
        overrides: [tabProvider.overrideWith(() => TabAt(AppTab.settings))]);
    await shoot(t, 'fa_setup_desktop', const SetupScreen(),
        size: desktop, locale: fa);
  });

  for (final locale in const [Locale('en'), Locale('fa')]) {
    testWidgets('crypto sheet ${locale.languageCode}', (t) async {
      await shoot(
        t,
        'crypto_sheet_phone_${locale.languageCode}',
        Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: FilledButton(
                onPressed: () => showCryptoSheet(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
        size: const Size(412, 892),
        dpr: 2.5,
        locale: locale,
        before: (t) async {
          await t.tap(find.text('open'));
        },
      );
    });
  }
}

