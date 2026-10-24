import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import '../data/settings.dart';
import 'models.dart';
import 'output_parser.dart';
import 'ytdlp_engine.dart';

/// Plain file downloads through aria2: one aria2c per app run, driven over
/// JSON-RPC on localhost so pause, resume and progress are structured
/// answers instead of scraped console lines.
class Aria2 {
  Aria2(this._engine, {http.Client? client})
      : _client = client ?? http.Client();

  final YtDlpEngine _engine;
  final http.Client _client;
  Future<Uri>? _endpoint;
  String _secret = '';
  final _gids = <String, String>{};
  final _cancelled = <String>{};

  static const pollInterval = Duration(seconds: 1);

  Stream<EngineEvent> download({
    required DownloadSpec spec,
    required AppSettings settings,
    required String outputDir,
    required String taskId,
  }) async* {
    _cancelled.remove(taskId);
    final proxy = settings.proxy?.trim() ?? '';
    final gid = await _call(settings, 'aria2.addUri', [
      [spec.url],
      {
        'dir': outputDir,
        'split': '${settings.connections}',
        'max-connection-per-server': '${settings.connections}',
        'min-split-size': '1M',
        if (settings.rateLimit?.trim().isNotEmpty ?? false)
          'max-download-limit': settings.rateLimit!.trim(),
        if (proxy.startsWith('http')) 'all-proxy': proxy,
      },
    ]) as String;
    _gids[taskId] = gid;
    if (_cancelled.contains(taskId)) await cancel(taskId);

    String? path;
    try {
      while (true) {
        final s = await _call(settings, 'aria2.tellStatus', [
          gid,
          ['status', 'totalLength', 'completedLength', 'downloadSpeed',
           'errorCode', 'errorMessage', 'files'],
        ]) as Map<String, dynamic>;
        final files = (s['files'] as List?) ?? const [];
        final found = files.isEmpty ? '' : '${(files.first as Map)['path']}';
        if (found.isNotEmpty && found != path) {
          path = found;
          // The server's name (Content-Disposition, redirects) wins.
          yield MetaEvent(MediaMeta(title: p.basename(found)));
        }
        switch (s['status']) {
          case 'active' || 'waiting':
            final progress = progressFrom(s);
            unawaited(_engine.trackFile(taskId,
                title: path == null ? null : p.basename(path),
                fraction: progress.fraction));
            yield ProgressEvent(progress);
          case 'complete':
            yield FileEvent(path ?? '');
            return;
          case 'error':
            throw failure(s['errorCode'], s['errorMessage']);
          case 'removed':
            if (path != null) {
              await _deleteQuietly(path);
              await _deleteQuietly('$path.aria2');
            }
            throw const CancelledException();
          // 'paused': nothing moves; keep asking until resumed.
        }
        await Future<void>.delayed(pollInterval);
      }
    } finally {
      _gids.remove(taskId);
      unawaited(_engine.untrackFile(taskId));
      unawaited(_tryCall(settings, 'aria2.removeDownloadResult', [gid]));
    }
  }

  Future<void> pause(String taskId) => _onGid(taskId, 'aria2.forcePause');

  Future<void> resume(String taskId) => _onGid(taskId, 'aria2.unpause');

  Future<void> cancel(String taskId) async {
    // Not added yet: download() removes it as soon as it has a gid.
    if (!_gids.containsKey(taskId)) {
      _cancelled.add(taskId);
      return;
    }
    await _onGid(taskId, 'aria2.forceRemove');
  }

  Future<void> _onGid(String taskId, String method) async {
    final gid = _gids[taskId];
    final endpoint = _endpoint;
    if (gid == null || endpoint == null) return;
    await _post(await endpoint, method, [gid]);
  }

  // ------------------------------------------------------------ rpc

  Future<Object?> _call(
      AppSettings settings, String method, List<Object?> params) async {
    final endpoint = _endpoint ??= _start(settings);
    try {
      return await _post(await endpoint, method, params);
    } on SocketException {
      // aria2c is gone (killed, crashed): start a fresh one next time.
      if (identical(_endpoint, endpoint)) _endpoint = null;
      throw EngineException(EngineErrorKind.engineStart, raw: 'aria2 stopped');
    }
  }

  Future<void> _tryCall(
      AppSettings settings, String method, List<Object?> params) async {
    try {
      await _call(settings, method, params);
    } catch (_) {}
  }

  Future<Object?> _post(Uri uri, String method, List<Object?> params) async {
    final res = await _client.post(
      uri,
      headers: {'content-type': 'application/json'},
      body: jsonEncode({
        'jsonrpc': '2.0',
        'id': 'snag',
        'method': method,
        'params': ['token:$_secret', ...params],
      }),
    );
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    final error = body['error'];
    if (error is Map) {
      throw EngineException(EngineErrorKind.unknown,
          raw: '${error['message']}', details: '$method: ${res.body}');
    }
    return body['result'];
  }

  Future<Uri> _start(AppSettings settings) async {
    try {
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;
      await socket.close();
      final rng = Random.secure();
      _secret = List.generate(16, (_) => rng.nextInt(256).toRadixString(16))
          .join();
      final cookies = settings.cookiesFile?.trim() ?? '';
      await _engine.startAria2([
        '--enable-rpc',
        '--rpc-listen-all=false',
        '--rpc-listen-port=$port',
        '--rpc-secret=$_secret',
        // Dies with Snag, whichever way Snag ends.
        '--stop-with-process=$pid',
        '--continue=true',
        '--auto-file-renaming=true',
        '--file-allocation=none',
        '--max-concurrent-downloads=16',
        '--console-log-level=warn',
        '--summary-interval=0',
        // shortcut: cookies are read once per aria2 run; a changed cookie
        // file applies after a restart of Snag.
        if (cookies.isNotEmpty) '--load-cookies=$cookies',
      ], settings);
      final uri = Uri.parse('http://127.0.0.1:$port/jsonrpc');
      for (var i = 0; i < 50; i++) {
        try {
          await _post(uri, 'aria2.getVersion', const []);
          return uri;
        } on SocketException {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        } on http.ClientException {
          await Future<void>.delayed(const Duration(milliseconds: 100));
        }
      }
      throw EngineException(EngineErrorKind.engineStart,
          raw: 'aria2 did not answer on port $port');
    } catch (_) {
      _endpoint = null;
      rethrow;
    }
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }
}

/// One `aria2.tellStatus` answer as Snag's progress.
ProgressUpdate progressFrom(Map<String, dynamic> s) {
  final total = int.tryParse('${s['totalLength']}') ?? 0;
  final done = int.tryParse('${s['completedLength']}') ?? 0;
  final speed = int.tryParse('${s['downloadSpeed']}') ?? 0;
  return ProgressUpdate(
    status: 'downloading',
    downloaded: done,
    // aria2 says 0 until the server has told it the size.
    total: total > 0 ? total : null,
    speed: speed > 0 ? speed.toDouble() : null,
    eta: total > 0 && speed > 0 ? (total - done) / speed : null,
  );
}

/// aria2's exit codes (see its manual, "EXIT STATUS") in Snag's terms.
EngineException failure(Object? code, Object? message) {
  final kind = switch (int.tryParse('$code')) {
    2 || 5 || 6 || 19 => EngineErrorKind.network,
    3 || 4 || 24 => EngineErrorKind.fileGone,
    9 || 15 || 16 || 17 => EngineErrorKind.folderNotWritable,
    _ => EngineErrorKind.unknown,
  };
  return EngineException(kind,
      raw: message == null ? null : '$message',
      details: 'aria2 error $code: $message');
}
