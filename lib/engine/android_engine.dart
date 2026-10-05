import 'dart:async';

import 'package:flutter/services.dart';

import '../data/settings.dart';
import 'args_builder.dart';
import 'ytdlp_engine.dart';

/// Android: talks to the Kotlin `YtDlpPlugin`, which runs yt-dlp through
/// youtubedl-android (embedded Python + ffmpeg) inside a foreground service.
class AndroidEngine extends YtDlpEngine {
  AndroidEngine() {
    _events.receiveBroadcastStream().listen(_onEvent);
  }

  static const _method = MethodChannel('snag/ytdlp');
  static const _events = EventChannel('snag/ytdlp/events');

  final _tasks = <String, StreamController<String>>{};
  Future<void>? _init;

  @override
  bool get allowsBrowserCookies => false;

  Future<void> _ensureInit() =>
      _init ??= _method.invokeMethod<void>('init').catchError((Object e) {
        _init = null;
        throw EngineException(EngineErrorKind.engineStart,
            details: _detailsOf(e));
      });

  static String _detailsOf(Object e) => e is PlatformException
      ? [e.message, e.details].whereType<String>().join('\n\n')
      : '$e';

  /// Runs a bridge call, turning platform errors into [EngineException]s.
  Future<T?> _call<T>(String method, [Map<String, Object?>? args]) async {
    try {
      return await _method.invokeMethod<T>(method, args);
    } on PlatformException catch (e) {
      final message = e.message ?? e.code;
      throw EngineException.fromYtDlp(_lastError(message),
          details: _detailsOf(e));
    }
  }

  void _onEvent(dynamic raw) {
    if (raw is! Map) return;
    final controller = _tasks[raw['taskId']];
    if (controller == null) return;
    switch (raw['type']) {
      case 'line':
        controller.add(raw['line'] as String);
      case 'done':
        _tasks.remove(raw['taskId']);
        controller.close();
      case 'cancelled':
        _tasks.remove(raw['taskId']);
        controller
          ..addError(const CancelledException())
          ..close();
      case 'error':
        _tasks.remove(raw['taskId']);
        final message = '${raw['message'] ?? 'Unknown error'}';
        controller
          ..addError(EngineException.fromYtDlp(_lastError(message),
              details: message))
          ..close();
    }
  }

  @override
  Future<ToolPaths> toolPaths(AppSettings settings) async {
    // youtubedl-android wires up its bundled ffmpeg itself.
    return const ToolPaths();
  }

  @override
  Future<String> defaultDownloadDir() async {
    return (await _call<String>('downloadsDir'))!;
  }

  @override
  Future<String> runToString(List<String> args, AppSettings settings) async {
    await _ensureInit();
    return await _call<String>('run', {'args': args}) ?? '';
  }

  @override
  Stream<String> runLines(
      List<String> args, AppSettings settings, String taskId) {
    final controller = StreamController<String>();
    _tasks[taskId] = controller;
    _ensureInit().then((_) {
      return _method.invokeMethod<void>('start', {
        'taskId': taskId,
        'args': args,
      });
    }).catchError((Object e) {
      _tasks.remove(taskId);
      controller
        ..addError(e is EngineException
            ? e
            : EngineException(EngineErrorKind.unknown, raw: '$e'))
        ..close();
    });
    return controller.stream;
  }

  @override
  Future<void> cancel(String taskId) =>
      _method.invokeMethod<void>('cancel', {'taskId': taskId});

  @override
  Future<String?> version(AppSettings settings) async {
    await _ensureInit();
    return _call<String>('version');
  }

  @override
  Future<UpdateResult> update(AppSettings settings) async {
    await _ensureInit();
    final status = await _call<String>('update', {
      'channel': settings.updateChannel.name,
    });
    return UpdateResult(
      changed: status == 'updated',
      version: await version(settings),
    );
  }

  static String _lastError(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty);
    final error = lines.lastWhere((l) => l.startsWith('ERROR:'),
        orElse: () => lines.isEmpty ? text : lines.last);
    return error.startsWith('ERROR:') ? error.substring(6).trim() : error;
  }
}
