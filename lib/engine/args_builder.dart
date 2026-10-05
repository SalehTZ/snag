import '../data/settings.dart';
import 'models.dart';
import 'output_parser.dart';

/// Locations of helper tools, resolved per platform. Null means "let yt-dlp
/// find it" (PATH on desktop, bundled on Android).
class ToolPaths {
  const ToolPaths({this.ffmpeg, this.deno, this.aria2c});
  final String? ffmpeg;
  final String? deno;
  final String? aria2c;
}

/// Builds yt-dlp argument lists. Pure, so every flag is unit-tested.
abstract final class ArgsBuilder {
  /// Arguments shared by every invocation.
  static List<String> common(AppSettings s, ToolPaths tools,
      {bool allowBrowserCookies = true}) {
    return [
      '--no-update',
      '--ignore-config',
      '--no-color',
      if (tools.deno != null) ...['--js-runtimes', 'deno:${tools.deno}'],
      if (tools.ffmpeg != null) ...['--ffmpeg-location', tools.ffmpeg!],
      if (_has(s.proxy)) ...['--proxy', s.proxy!.trim()],
      if (_has(s.cookiesFile)) ...['--cookies', s.cookiesFile!]
      else if (allowBrowserCookies && _has(s.cookiesFromBrowser))
        ...['--cookies-from-browser', s.cookiesFromBrowser!.trim()],
    ];
  }

  /// `-J` returns a single JSON document for a video or a flat playlist.
  static List<String> info(String url, AppSettings s, ToolPaths tools,
      {bool allowBrowserCookies = true}) {
    return [
      ...common(s, tools, allowBrowserCookies: allowBrowserCookies),
      '-J',
      '--flat-playlist',
      '--no-warnings',
      '--',
      url,
    ];
  }

  static List<String> download({
    required DownloadSpec spec,
    required AppSettings settings,
    required ToolPaths tools,
    required String outputDir,
    bool allowBrowserCookies = true,
  }) {
    final s = settings;
    final args = <String>[
      ...common(s, tools, allowBrowserCookies: allowBrowserCookies),
      // Machine-readable plumbing. `--print` implies --quiet, so force the
      // progress output back on.
      '--newline',
      '--progress',
      '--no-simulate',
      '--progress-template', 'download:${Marker.progress}%(progress)j',
      '--progress-template',
      'postprocess:${Marker.postprocess}%(progress.postprocessor)s|%(progress.status)s',
      '--print',
      'pre_process:${Marker.info}%(.{id,title,uploader,channel,thumbnail,duration,extractor_key})j',
      '--print', 'after_move:${Marker.file}%(filepath)s',
      // Output.
      '-P', outputDir,
      '-o', s.filenameTemplate.trim().isEmpty
          ? AppSettings.defaultFilenameTemplate
          : s.filenameTemplate,
      '--no-mtime',
      '--no-playlist',
      if (s.restrictFilenames) '--restrict-filenames',
      if (_has(s.rateLimit)) ...['--limit-rate', s.rateLimit!.trim()],
      if (s.useAria2c) ...[
        '--downloader', tools.aria2c ?? 'aria2c',
        '--downloader-args', 'aria2c:-x 8 -s 8 -k 1M',
      ],
    ];

    if (spec.templateArgs != null) {
      args.addAll(splitArgs(spec.templateArgs!));
    } else {
      args.addAll(_formatArgs(spec, s));
      args.addAll(_postprocessArgs(spec, s));
    }

    args.addAll(splitArgs(s.extraArgs));
    args.add('--');
    args.add(spec.url);
    return args;
  }

  static List<String> _formatArgs(DownloadSpec spec, AppSettings s) {
    if (spec.formatId != null) {
      return ['-f', spec.formatId!];
    }
    if (spec.mode == DownloadMode.audio) {
      return [
        '-f', 'ba/b',
        '-x',
        if (spec.audioFormat.codec != null) ...[
          '--audio-format', spec.audioFormat.codec!,
        ],
        '--audio-quality', '0',
      ];
    }
    // Video: a sort order instead of a hard filter means we never fail with
    // "format not available"; we just get the closest match.
    final sort = <String>[
      spec.quality.height != null ? 'res:${spec.quality.height}' : 'res',
      if (s.preferCompatible) ...['vcodec:h264', 'acodec:aac'],
    ];
    return [
      '-f', 'bv*+ba/b',
      '-S', sort.join(','),
      if (s.preferCompatible) ...['--merge-output-format', 'mp4'],
    ];
  }

  static List<String> _postprocessArgs(DownloadSpec spec, AppSettings s) {
    final isAudio = spec.mode == DownloadMode.audio && spec.formatId == null;
    final subs = spec.subtitles ?? s.embedSubtitles;
    return [
      if (s.embedMetadata) '--embed-metadata',
      if (s.embedThumbnail) ...[
        '--embed-thumbnail',
        '--convert-thumbnails', 'jpg',
      ],
      if (s.embedChapters && !isAudio) '--embed-chapters',
      if (subs && !isAudio) ...[
        '--write-subs',
        '--sub-langs', s.subtitleLangs.trim().isEmpty ? 'en.*' : s.subtitleLangs,
        '--embed-subs',
      ],
      if (s.sponsorBlock == SponsorBlockMode.mark) ...[
        '--sponsorblock-mark', 'all',
      ],
      if (s.sponsorBlock == SponsorBlockMode.remove) ...[
        '--sponsorblock-remove', 'sponsor,selfpromo,interaction',
      ],
    ];
  }

  /// Splits a command line like a POSIX shell would (quotes and escapes),
  /// without ever invoking a shell.
  static List<String> splitArgs(String input) {
    final out = <String>[];
    final buf = StringBuffer();
    var inToken = false;
    String? quote;
    for (var i = 0; i < input.length; i++) {
      final c = input[i];
      if (quote != null) {
        if (c == quote) {
          quote = null;
        } else if (c == r'\' && quote == '"' && i + 1 < input.length) {
          buf.write(input[++i]);
        } else {
          buf.write(c);
        }
      } else if (c == '"' || c == "'") {
        quote = c;
        inToken = true;
      } else if (c == r'\' && i + 1 < input.length) {
        buf.write(input[++i]);
        inToken = true;
      } else if (c.trim().isEmpty) {
        if (inToken) {
          out.add(buf.toString());
          buf.clear();
          inToken = false;
        }
      } else {
        buf.write(c);
        inToken = true;
      }
    }
    if (inToken) out.add(buf.toString());
    return out;
  }

  static bool _has(String? v) => v != null && v.trim().isNotEmpty;
}
