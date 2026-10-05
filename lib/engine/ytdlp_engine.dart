import 'dart:async';
import 'dart:convert';

import '../data/settings.dart';
import 'args_builder.dart';
import 'models.dart';
import 'output_parser.dart';

/// What went wrong, so the UI can explain it in the user's language.
enum EngineErrorKind {
  botCheck,
  unsupportedUrl,
  privateVideo,
  signInRequired,
  rateLimited,
  network,
  ffmpegMissing,
  formatUnavailable,
  notInstalled,
  noMedia,
  unexpectedOutput,
  folderNotWritable,
  engineStart,
  invalidLink,
  unknown,
}

class EngineException implements Exception {
  EngineException(this.kind, {this.raw, this.details});

  /// Classifies a raw yt-dlp error line.
  factory EngineException.fromYtDlp(String raw, {String? details}) =>
      EngineException(classifyError(raw), raw: raw, details: details);

  final EngineErrorKind kind;

  /// yt-dlp's own (English) message, shown when [kind] is unknown.
  final String? raw;

  /// Raw output for the "details" disclosure.
  final String? details;

  @override
  String toString() => raw ?? kind.name;
}

/// Outcome of a yt-dlp self-update.
class UpdateResult {
  const UpdateResult({required this.changed, this.version});
  final bool changed;
  final String? version;
}

class CancelledException implements Exception {
  const CancelledException();
}

/// Platform-neutral access to yt-dlp. Subclasses only implement the two
/// process primitives; argument building and parsing are shared.
abstract class YtDlpEngine {
  /// `--cookies-from-browser` only makes sense where a desktop browser exists.
  bool get allowsBrowserCookies;

  Future<ToolPaths> toolPaths(AppSettings settings);

  Future<String> defaultDownloadDir();

  /// Runs yt-dlp to completion and returns stdout.
  Future<String> runToString(List<String> args, AppSettings settings);

  /// Runs yt-dlp and streams every output line (stdout and, where the
  /// platform allows, stderr). Completes when the process exits successfully;
  /// errors with [EngineException] or [CancelledException] otherwise.
  Stream<String> runLines(
      List<String> args, AppSettings settings, String taskId);

  Future<void> cancel(String taskId);

  Future<String?> version(AppSettings settings);

  Future<UpdateResult> update(AppSettings settings);

  Future<MediaInfo> fetchInfo(String url, AppSettings settings) async {
    final tools = await toolPaths(settings);
    final args = ArgsBuilder.info(url, settings, tools,
        allowBrowserCookies: allowsBrowserCookies);
    final out = await runToString(args, settings);
    final start = out.indexOf('{');
    if (start < 0) {
      throw EngineException(EngineErrorKind.noMedia, details: out);
    }
    try {
      final json = jsonDecode(out.substring(start)) as Map<String, dynamic>;
      return MediaInfo.fromJson(json, requestedUrl: url);
    } on FormatException catch (e) {
      throw EngineException(EngineErrorKind.unexpectedOutput,
          details: '$e\n$out');
    }
  }

  Stream<EngineEvent> download({
    required DownloadSpec spec,
    required AppSettings settings,
    required String outputDir,
    required String taskId,
  }) async* {
    final tools = await toolPaths(settings);
    final args = ArgsBuilder.download(
      spec: spec,
      settings: settings,
      tools: tools,
      outputDir: outputDir,
      allowBrowserCookies: allowsBrowserCookies,
    );
    yield* runLines(args, settings, taskId).map(EngineEvent.parse);
  }
}
