import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../core/app_info.dart';
import '../data/settings.dart';
import 'args_builder.dart';
import 'binary_manager.dart';
import 'output_parser.dart';
import 'ytdlp_engine.dart';

/// Linux / Windows / macOS: spawns the yt-dlp binary directly.
class DesktopEngine extends YtDlpEngine {
  DesktopEngine(this.binaries);

  final BinaryManager binaries;
  final _running = <String, Process>{};
  final _cancelled = <String>{};

  static const _env = {'PYTHONIOENCODING': 'utf-8', 'PYTHONUTF8': '1'};

  @override
  bool get allowsBrowserCookies => true;

  Future<String> _ytDlp(AppSettings s) async {
    final status =
        await binaries.resolve(Component.ytDlp, override: s.ytDlpPath);
    if (!status.available) {
      throw EngineException(
          'yt-dlp is not installed yet. Open Settings > Components to set it up.');
    }
    return status.path!;
  }

  @override
  Future<ToolPaths> toolPaths(AppSettings s) async {
    final ffmpeg =
        await binaries.resolve(Component.ffmpeg, override: s.ffmpegPath);
    final deno = await binaries.resolve(Component.deno);
    return ToolPaths(
      // A directory lets yt-dlp find ffprobe next to ffmpeg.
      ffmpeg: ffmpeg.path == null ? null : p.dirname(ffmpeg.path!),
      deno: deno.path,
    );
  }

  @override
  Future<String> defaultDownloadDir() async {
    final downloads = await getDownloadsDirectory();
    final base = downloads?.path ??
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        (await getApplicationDocumentsDirectory()).path;
    return p.join(base, AppInfo.name);
  }

  @override
  Future<String> runToString(List<String> args, AppSettings settings) async {
    final exe = await _ytDlp(settings);
    final result = await Process.run(
      exe,
      args,
      environment: _env,
      stdoutEncoding: const Utf8Codec(allowMalformed: true),
      stderrEncoding: const Utf8Codec(allowMalformed: true),
    );
    if (result.exitCode != 0) {
      throw _failure('${result.stderr}');
    }
    return '${result.stdout}';
  }

  @override
  Stream<String> runLines(
      List<String> args, AppSettings settings, String taskId) {
    final controller = StreamController<String>();
    final errors = <String>[];

    Future<void> run() async {
      final exe = await _ytDlp(settings);
      final process = await Process.start(exe, args, environment: _env);
      _running[taskId] = process;

      Stream<String> lines(Stream<List<int>> s) => s
          .transform(const Utf8Decoder(allowMalformed: true))
          .transform(const LineSplitter());

      // Completion futures must exist before the pipes can close, or a fast
      // process finishes before anyone is listening for "done".
      final outDone = lines(process.stdout).forEach(controller.add);
      // yt-dlp prints postprocessor progress and errors on stderr.
      final errDone = lines(process.stderr).forEach((line) {
        errors.add(line);
        if (errors.length > 80) errors.removeAt(0);
        controller.add(line);
      });

      final code = await process.exitCode;
      await Future.wait([outDone, errDone]);
      _running.remove(taskId);

      if (_cancelled.remove(taskId)) {
        controller.addError(const CancelledException());
      } else if (code != 0) {
        controller.addError(_failure(errors.join('\n'), code: code));
      }
    }

    run()
        .catchError((Object e, StackTrace st) => controller.addError(e, st))
        .whenComplete(controller.close);
    return controller.stream;
  }

  @override
  Future<void> cancel(String taskId) async {
    final process = _running[taskId];
    if (process == null) return;
    _cancelled.add(taskId);
    // SIGINT lets yt-dlp stop ffmpeg children cleanly; escalate if it hangs.
    process.kill(Platform.isWindows ? ProcessSignal.sigterm : ProcessSignal.sigint);
    unawaited(Future.delayed(const Duration(seconds: 4), () {
      if (_running.containsKey(taskId)) process.kill(ProcessSignal.sigkill);
    }));
  }

  @override
  Future<String?> version(AppSettings settings) async {
    final status = await binaries.withVersion(
        await binaries.resolve(Component.ytDlp, override: settings.ytDlpPath));
    return status.version;
  }

  @override
  Future<String> update(AppSettings settings) async {
    final status =
        await binaries.resolve(Component.ytDlp, override: settings.ytDlpPath);
    if (status.source != ComponentSource.managed) {
      // Never self-update a binary we do not own (apt, brew, pip...).
      await binaries.install(Component.ytDlp);
      return 'Installed the latest yt-dlp into ${AppInfo.name}.';
    }
    return binaries.updateYtDlp(status.path!,
        nightly: settings.updateChannel == UpdateChannel.nightly);
  }

  EngineException _failure(String stderr, {int? code}) {
    final lines = stderr
        .split('\n')
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();
    final errorLine = lines.lastWhere((l) => l.startsWith('ERROR:'),
        orElse: () => lines.isEmpty ? 'yt-dlp exited with code $code' : lines.last);
    final raw = errorLine.startsWith('ERROR:')
        ? errorLine.substring(6).trim()
        : errorLine;
    return EngineException(friendlyError(raw), details: stderr.trim());
  }
}
