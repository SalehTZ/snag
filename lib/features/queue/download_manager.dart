import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/records.dart';
import '../../engine/aria2.dart';
import '../../engine/models.dart';
import '../../engine/output_parser.dart';
import '../../engine/ytdlp_engine.dart';

enum TaskStatus {
  queued,
  running,
  paused,
  processing,
  completed,
  failed,
  cancelled,
}

@immutable
class DownloadTask {
  const DownloadTask({
    required this.id,
    required this.spec,
    required this.meta,
    required this.createdAt,
    this.status = TaskStatus.queued,
    this.progress,
    this.stage,
    this.filePath,
    this.failure,
    this.log = const [],
  });

  final String id;
  final DownloadSpec spec;
  final MediaMeta meta;
  final DateTime createdAt;
  final TaskStatus status;
  final ProgressUpdate? progress;

  /// Name of the yt-dlp post-processor that is running (e.g. "Merger").
  final String? stage;
  final String? filePath;

  /// Why it failed; localized by the UI.
  final EngineException? failure;
  final List<String> log;

  String get title => meta.title ?? spec.url;
  bool get isActive =>
      status == TaskStatus.queued ||
      status == TaskStatus.running ||
      status == TaskStatus.paused ||
      status == TaskStatus.processing;
  bool get isFinished => !isActive;

  DownloadTask copyWith({
    MediaMeta? meta,
    TaskStatus? status,
    ProgressUpdate? Function()? progress,
    String? Function()? stage,
    String? filePath,
    EngineException? Function()? failure,
    List<String>? log,
  }) {
    return DownloadTask(
      id: id,
      spec: spec,
      createdAt: createdAt,
      meta: meta ?? this.meta,
      status: status ?? this.status,
      progress: progress != null ? progress() : this.progress,
      stage: stage != null ? stage() : this.stage,
      filePath: filePath ?? this.filePath,
      failure: failure != null ? failure() : this.failure,
      log: log ?? this.log,
    );
  }
}

/// Owns the download queue: concurrency, lifecycle, and handing finished
/// work to the history.
class DownloadManager extends Notifier<List<DownloadTask>> {
  final _subs = <String, StreamSubscription<EngineEvent>>{};
  final _lastEmit = <String, DateTime>{};
  final _rng = Random();

  @override
  List<DownloadTask> build() {
    ref.onDispose(() {
      for (final s in _subs.values) {
        s.cancel();
      }
    });
    // Raising the concurrency limit should start waiting downloads at once.
    ref.listen(settingsProvider.select((s) => s.concurrency), (_, _) => _pump());
    return const [];
  }

  YtDlpEngine get _engine => ref.read(engineProvider);
  Aria2 get _aria2 => ref.read(aria2Provider);

  String _newId() =>
      '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}'
      '${_rng.nextInt(1 << 20).toRadixString(36)}';

  void enqueue(DownloadSpec spec, MediaMeta meta) {
    enqueueAll([(spec, meta)]);
  }

  void enqueueAll(List<(DownloadSpec, MediaMeta)> items) {
    final now = DateTime.now();
    state = [
      ...state,
      for (final (spec, meta) in items)
        DownloadTask(id: _newId(), spec: spec, meta: meta, createdAt: now),
    ];
    _pump();
  }

  Future<void> cancel(String id) async {
    final task = _find(id);
    if (task == null) return;
    if (task.status == TaskStatus.queued) {
      _patch(id, (t) => t.copyWith(status: TaskStatus.cancelled));
      return;
    }
    if (task.spec.kind == DownloadKind.file) return _aria2.cancel(id);
    await _engine.cancel(id);
  }

  /// File downloads only: aria2 can stop and pick up where it left off.
  Future<void> pause(String id) async {
    _patch(id, (t) => t.copyWith(status: TaskStatus.paused));
    await _aria2.pause(id);
    // A paused download no longer holds a slot.
    _pump();
  }

  Future<void> resume(String id) async {
    _patch(id, (t) => t.copyWith(status: TaskStatus.running));
    await _aria2.resume(id);
  }

  void retry(String id) {
    _patch(
      id,
      (t) => t.copyWith(
        status: TaskStatus.queued,
        progress: () => null,
        stage: () => null,
        failure: () => null,
        log: const [],
      ),
    );
    _pump();
  }

  void remove(String id) {
    _subs.remove(id)?.cancel();
    state = state.where((t) => t.id != id).toList();
  }

  void clearFinished() {
    state = state.where((t) => t.isActive).toList();
  }

  void retryAllFailed() {
    for (final t in state.where((t) => t.status == TaskStatus.failed)) {
      retry(t.id);
    }
  }

  // ------------------------------------------------------------ internals

  DownloadTask? _find(String id) =>
      state.where((t) => t.id == id).firstOrNull;

  void _patch(String id, DownloadTask Function(DownloadTask) change) {
    state = [for (final t in state) t.id == id ? change(t) : t];
  }

  void _pump() {
    final limit = ref.read(settingsProvider).concurrency;
    var running = state
        .where((t) =>
            t.status == TaskStatus.running ||
            t.status == TaskStatus.processing)
        .length;
    for (final task in state) {
      if (running >= limit) break;
      if (task.status == TaskStatus.queued) {
        running++;
        _start(task);
      }
    }
  }

  Future<void> _start(DownloadTask task) async {
    _patch(task.id, (t) => t.copyWith(status: TaskStatus.running));
    final settings = ref.read(settingsProvider);
    String outputDir;
    try {
      outputDir = settings.downloadDir ?? await _engine.defaultDownloadDir();
      await Directory(outputDir).create(recursive: true);
    } catch (e) {
      _fail(task.id,
          EngineException(EngineErrorKind.folderNotWritable, details: '$e'));
      _pump();
      return;
    }

    final stream = (task.spec.kind == DownloadKind.file
        ? _aria2.download
        : _engine.download)(
      spec: task.spec,
      settings: settings,
      outputDir: outputDir,
      taskId: task.id,
    );
    _subs[task.id] = stream.listen(
      (event) => _onEvent(task.id, event),
      onError: (Object e) {
        if (e is CancelledException) {
          _patch(task.id, (t) => t.copyWith(
              status: TaskStatus.cancelled, stage: () => null));
        } else {
          _fail(task.id, e);
        }
        _subs.remove(task.id);
        _pump();
      },
      onDone: () {
        _subs.remove(task.id);
        final t = _find(task.id);
        if (t != null && t.isActive) _complete(t);
        _pump();
      },
      cancelOnError: true,
    );
  }

  void _onEvent(String id, EngineEvent event) {
    switch (event) {
      case ProgressEvent(:final progress):
        // Throttle UI rebuilds to ~10 fps per task, but always show the end.
        final now = DateTime.now();
        final last = _lastEmit[id];
        final done = progress.status == 'finished';
        // A poll that left aria2 before the pause landed.
        if (_find(id)?.status == TaskStatus.paused) return;
        if (!done &&
            last != null &&
            now.difference(last) < const Duration(milliseconds: 100)) {
          return;
        }
        _lastEmit[id] = now;
        _patch(id, (t) => t.copyWith(
              status: TaskStatus.running,
              progress: () => progress,
              stage: () => null,
            ));
      case PostprocessEvent():
        _patch(id, (t) => t.copyWith(
              status: TaskStatus.processing,
              stage: () => event.name,
            ));
      case MetaEvent(:final meta):
        // yt-dlp's own metadata is authoritative; keep ours as fallback.
        _patch(id, (t) => t.copyWith(meta: meta.merge(t.meta)));
      case FileEvent(:final path):
        _patch(id, (t) => t.copyWith(filePath: path));
      case LogEvent(:final message):
        if (message.isEmpty) return;
        _patch(id, (t) {
          final log = [...t.log, message];
          return t.copyWith(
              log: log.length > 200 ? log.sublist(log.length - 200) : log);
        });
    }
  }

  void _fail(String id, Object e) {
    _patch(id, (t) {
      final ex = e is EngineException
          ? e
          : EngineException(EngineErrorKind.unknown,
              raw: '$e', details: t.log.join('\n'));
      return t.copyWith(
        status: TaskStatus.failed,
        stage: () => null,
        failure: () => ex,
      );
    });
  }

  Future<void> _complete(DownloadTask task) async {
    _patch(task.id, (t) => t.copyWith(
          status: TaskStatus.completed,
          stage: () => null,
        ));
    int? size;
    if (task.filePath != null) {
      try {
        size = await File(task.filePath!).length();
      } catch (_) {}
    }
    ref.read(historyProvider.notifier).add(HistoryItem(
          id: task.id,
          spec: task.spec,
          meta: task.meta,
          finishedAt: DateTime.now(),
          filePath: task.filePath,
          fileSize: size,
        ));
  }
}

final downloadManagerProvider =
    NotifierProvider<DownloadManager, List<DownloadTask>>(DownloadManager.new);

/// Count of active tasks, for the nav badge.
final activeCountProvider = Provider<int>((ref) =>
    ref.watch(downloadManagerProvider).where((t) => t.isActive).length);
