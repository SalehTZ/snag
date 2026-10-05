// ignore_for_file: invalid_use_of_visible_for_testing_member
// Real end-to-end check of the desktop engine: downloads the official yt-dlp
// release, then downloads real media through Snag's arguments and parser.
// Needs network. Run with:
//
//   flutter test tool/e2e
@Tags(['e2e'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:snag/data/settings.dart';
import 'package:snag/engine/binary_manager.dart';
import 'package:snag/engine/desktop_engine.dart';
import 'package:snag/engine/models.dart';
import 'package:snag/engine/output_parser.dart';
import 'package:snag/engine/ytdlp_engine.dart';

class TempPaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  TempPaths(this.root);
  final String root;
  @override
  Future<String?> getApplicationSupportPath() async => '$root/support';
  @override
  Future<String?> getDownloadsPath() async => '$root/downloads';
}

const videoWithAudio = 'https://download.samplelib.com/mp4/sample-5s.mp4';
const longerVideo = 'https://download.samplelib.com/mp4/sample-30s.mp4';

void main() {
  late Directory root;
  late BinaryManager bins;
  late DesktopEngine engine;
  late String out;
  const settings = AppSettings(embedThumbnail: false);

  setUpAll(() async {
    root = Directory.systemTemp.createTempSync('snag-e2e');
    PathProviderPlatform.instance = TempPaths(root.path);
    bins = BinaryManager();
    engine = DesktopEngine(bins);
    out = '${root.path}/downloads/Snag';
    Directory(out).createSync(recursive: true);
  });

  tearDownAll(() => root.deleteSync(recursive: true));

  test('installs the latest yt-dlp release into app support', () async {
    final stages = <InstallStage>{};
    double? last;
    await bins.install(Component.ytDlp, onProgress: (f, stage) {
      stages.add(stage);
      last = f;
    });
    final status = await bins.withVersion(await bins.resolve(Component.ytDlp));
    expect(status.source, ComponentSource.managed);
    expect(status.version, matches(RegExp(r'^\d{4}\.\d{2}\.\d{2}')));
    expect(last, closeTo(1.0, 0.0001));
    // ignore: avoid_print
    print('yt-dlp ${status.version} at ${status.path}');
  }, timeout: const Timeout(Duration(minutes: 5)));

  test('fetchInfo parses a real response', () async {
    final info = await engine.fetchInfo(videoWithAudio, settings);
    expect(info.isPlaylist, isFalse);
    expect(info.title, isNotEmpty);
    expect(info.extractor, 'Generic');
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('video download streams progress and reports the final file', () async {
    final events = await engine
        .download(
          spec: const DownloadSpec(url: videoWithAudio),
          settings: settings,
          outputDir: out,
          taskId: 'v',
        )
        .toList();
    final progress = events.whereType<ProgressEvent>().toList();
    final files = events.whereType<FileEvent>().toList();
    expect(events.whereType<MetaEvent>(), isNotEmpty);
    expect(progress, isNotEmpty);
    expect(progress.last.progress.fraction, 1.0);
    expect(files, hasLength(1));
    expect(File(files.single.path).existsSync(), isTrue);
    expect(files.single.path, endsWith('.mp4'));
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('audio mode converts to mp3 with ffmpeg', () async {
    final events = await engine
        .download(
          spec: const DownloadSpec(
              url: videoWithAudio,
              mode: DownloadMode.audio,
              audioFormat: AudioFormat.mp3),
          settings: settings,
          outputDir: out,
          taskId: 'a',
        )
        .toList();
    final file = events.whereType<FileEvent>().single.path;
    expect(file, endsWith('.mp3'));
    expect(File(file).lengthSync(), greaterThan(1000));
    expect(
      events.whereType<PostprocessEvent>().map((e) => e.name),
      contains('ExtractAudio'),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('cancel stops the process with CancelledException', () async {
    final stream = engine.download(
      spec: const DownloadSpec(url: longerVideo),
      settings: settings.copyWith(rateLimit: () => '50K'),
      outputDir: out,
      taskId: 'c',
    );
    Object? error;
    var gotProgress = false;
    try {
      await for (final e in stream) {
        if (e is ProgressEvent && !gotProgress) {
          gotProgress = true;
          await engine.cancel('c');
        }
      }
    } catch (e) {
      error = e;
    }
    expect(gotProgress, isTrue);
    expect(error, isA<CancelledException>());
  }, timeout: const Timeout(Duration(minutes: 2)));

  test('a bad link produces a friendly EngineException', () async {
    await expectLater(
      engine.fetchInfo('https://example.com/definitely-not-a-video', settings),
      throwsA(isA<EngineException>()),
    );
  }, timeout: const Timeout(Duration(minutes: 2)));
}
