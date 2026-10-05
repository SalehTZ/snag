import 'package:flutter_test/flutter_test.dart';
import 'package:snag/data/settings.dart';
import 'package:snag/engine/args_builder.dart';
import 'package:snag/engine/models.dart';

List<String> build(DownloadSpec spec,
        {AppSettings settings = const AppSettings(),
        ToolPaths tools = const ToolPaths(),
        bool browserCookies = true}) =>
    ArgsBuilder.download(
      spec: spec,
      settings: settings,
      tools: tools,
      outputDir: '/out',
      allowBrowserCookies: browserCookies,
    );

/// Value following [flag], or null.
String? valueOf(List<String> args, String flag) {
  final i = args.indexOf(flag);
  return i >= 0 && i + 1 < args.length ? args[i + 1] : null;
}

void main() {
  const url = 'https://example.com/watch?v=1';

  group('download args', () {
    test('url is last and protected by --', () {
      final args = build(const DownloadSpec(url: url));
      expect(args.last, url);
      expect(args[args.length - 2], '--');
    });

    test('machine-readable plumbing is always present', () {
      final args = build(const DownloadSpec(url: url));
      expect(args, containsAll(['--newline', '--progress', '--no-simulate']));
      expect(args.where((a) => a.startsWith('download:SNAG_P')), hasLength(1));
      expect(args.where((a) => a.startsWith('after_move:SNAG_F')), hasLength(1));
      expect(valueOf(args, '-P'), '/out');
    });

    test('best video sorts by resolution, compatible by default', () {
      final args = build(const DownloadSpec(url: url));
      expect(valueOf(args, '-f'), 'bv*+ba/b');
      expect(valueOf(args, '-S'), 'res,vcodec:h264,acodec:aac');
      expect(valueOf(args, '--merge-output-format'), 'mp4');
    });

    test('height cap becomes a sort preference, never a hard filter', () {
      final args = build(const DownloadSpec(url: url, quality: VideoQuality.p720),
          settings: const AppSettings(preferCompatible: false));
      expect(valueOf(args, '-S'), 'res:720');
      expect(args, isNot(contains('--merge-output-format')));
    });

    test('audio extracts with the chosen codec, no chapters or subs', () {
      final args = build(const DownloadSpec(
          url: url, mode: DownloadMode.audio, audioFormat: AudioFormat.opus,
          subtitles: true));
      expect(args, contains('-x'));
      expect(valueOf(args, '--audio-format'), 'opus');
      expect(args, isNot(contains('--embed-subs')));
      expect(args, isNot(contains('--embed-chapters')));
    });

    test('"best" audio keeps the original codec', () {
      final args = build(const DownloadSpec(
          url: url, mode: DownloadMode.audio, audioFormat: AudioFormat.best));
      expect(args, contains('-x'));
      expect(args, isNot(contains('--audio-format')));
    });

    test('explicit format id wins over presets', () {
      final args = build(const DownloadSpec(url: url, formatId: '137+ba/137'));
      expect(valueOf(args, '-f'), '137+ba/137');
      expect(args, isNot(contains('-S')));
    });

    test('subtitles per-download override beats the setting', () {
      final on = build(const DownloadSpec(url: url, subtitles: true));
      expect(on, contains('--embed-subs'));
      expect(valueOf(on, '--sub-langs'), 'en.*');
      final off = build(const DownloadSpec(url: url, subtitles: false),
          settings: const AppSettings(embedSubtitles: true));
      expect(off, isNot(contains('--embed-subs')));
    });

    test('templates replace format and post-processing flags', () {
      final args = build(const DownloadSpec(
          url: url, templateArgs: '-f "bv*+ba" --merge-output-format mkv'));
      expect(valueOf(args, '-f'), 'bv*+ba');
      expect(valueOf(args, '--merge-output-format'), 'mkv');
      expect(args, isNot(contains('--embed-metadata')));
      expect(args, isNot(contains('-S')));
      // Plumbing survives.
      expect(args, contains('--newline'));
    });

    test('network, cookies and tools', () {
      final args = build(
        const DownloadSpec(url: url),
        settings: const AppSettings(
          proxy: 'socks5://127.0.0.1:1080',
          rateLimit: '2M',
          cookiesFromBrowser: 'firefox',
        ),
        tools: const ToolPaths(ffmpeg: '/bin/ff', deno: '/bin/deno'),
      );
      expect(valueOf(args, '--proxy'), 'socks5://127.0.0.1:1080');
      expect(valueOf(args, '--limit-rate'), '2M');
      expect(valueOf(args, '--cookies-from-browser'), 'firefox');
      expect(valueOf(args, '--ffmpeg-location'), '/bin/ff');
      expect(valueOf(args, '--js-runtimes'), 'deno:/bin/deno');
    });

    test('cookie file beats browser cookies; browser cookies off on mobile', () {
      final both = build(const DownloadSpec(url: url),
          settings: const AppSettings(
              cookiesFile: '/c.txt', cookiesFromBrowser: 'chrome'));
      expect(valueOf(both, '--cookies'), '/c.txt');
      expect(both, isNot(contains('--cookies-from-browser')));
      final mobile = build(const DownloadSpec(url: url),
          settings: const AppSettings(cookiesFromBrowser: 'chrome'),
          browserCookies: false);
      expect(mobile, isNot(contains('--cookies-from-browser')));
    });

    test('sponsorblock modes', () {
      expect(
          build(const DownloadSpec(url: url),
              settings: const AppSettings(sponsorBlock: SponsorBlockMode.remove)),
          contains('--sponsorblock-remove'));
      expect(
          build(const DownloadSpec(url: url),
              settings: const AppSettings(sponsorBlock: SponsorBlockMode.mark)),
          contains('--sponsorblock-mark'));
    });

    test('empty filename template falls back to default', () {
      final args = build(const DownloadSpec(url: url),
          settings: const AppSettings(filenameTemplate: '  '));
      expect(valueOf(args, '-o'), AppSettings.defaultFilenameTemplate);
    });
  });

  group('splitArgs', () {
    test('handles quotes and escapes like a shell', () {
      expect(
          ArgsBuilder.splitArgs(
              r'''-f "bv*+ba/b" -o '%(title)s.%(ext)s' a\ b'''),
          ['-f', 'bv*+ba/b', '-o', '%(title)s.%(ext)s', 'a b']);
    });

    test('empty quoted argument is kept', () {
      expect(ArgsBuilder.splitArgs('--foo "" --bar'), ['--foo', '', '--bar']);
    });

    test('whitespace only gives nothing', () {
      expect(ArgsBuilder.splitArgs('   \n '), isEmpty);
    });
  });

  test('info args', () {
    final args = ArgsBuilder.info(url, const AppSettings(), const ToolPaths());
    expect(args, containsAll(['-J', '--flat-playlist']));
    expect(args.last, url);
  });
}
