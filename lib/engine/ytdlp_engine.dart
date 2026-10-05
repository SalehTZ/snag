import 'dart:async';
import 'dart:convert';

import '../data/settings.dart';
import 'args_builder.dart';
import 'models.dart';
import 'output_parser.dart';

class EngineException implements Exception {
  EngineException(this.message, {this.details});

  /// Friendly, actionable message.
  final String message;

  /// Raw yt-dlp output for the "details" disclosure.
  final String? details;

  @override
  String toString() => message;
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

  Future<String> update(AppSettings settings);

  Future<MediaInfo> fetchInfo(String url, AppSettings settings) async {
    final tools = await toolPaths(settings);
    final args = ArgsBuilder.info(url, settings, tools,
        allowBrowserCookies: allowsBrowserCookies);
    final out = await runToString(args, settings);
    final start = out.indexOf('{');
    if (start < 0) {
      throw EngineException('No media found at this link.', details: out);
    }
    try {
      final json = jsonDecode(out.substring(start)) as Map<String, dynamic>;
      return MediaInfo.fromJson(json, requestedUrl: url);
    } on FormatException catch (e) {
      throw EngineException('yt-dlp returned something unexpected.',
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
