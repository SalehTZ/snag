import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../data/settings.dart';
import 'file_probe.dart';
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
  final _probes = <String, String>{};
  // Finished torrents still uploading, by their result path.
  final _seeding = <String, String>{};

  @visibleForTesting
  static Duration pollInterval = const Duration(seconds: 1);

  Stream<EngineEvent> download({
    required DownloadSpec spec,
    required AppSettings settings,
    required String outputDir,
    required String taskId,
  }) async* {
    _cancelled.remove(taskId);
    var gid = await _add(settings, spec.url, {
      'dir': outputDir,
      'split': '${settings.connections}',
      'max-connection-per-server': '${settings.connections}',
      'min-split-size': '1M',
      // Torrents only; aria2 also stops once the share ratio reaches 1.0.
      'seed-time': '${settings.seedHours * 60}',
      if (settings.rateLimit?.trim().isNotEmpty ?? false)
        'max-download-limit': settings.rateLimit!.trim(),
      ..._proxy(settings),
      if (spec.files case final files?) 'select-file': files.join(','),
    });
    _gids[taskId] = gid;
    if (_cancelled.contains(taskId)) await cancel(taskId);

    String? path;
    var files = const <String>[];
    try {
      while (true) {
        final s = await _call(settings, 'aria2.tellStatus', [
          gid,
          ['status', 'totalLength', 'completedLength', 'downloadSpeed',
           'errorCode', 'errorMessage', 'dir', 'files', 'bittorrent',
           'followedBy', 'seeder'],
        ]) as Map<String, dynamic>;
        final found = resultPath(s);
        if (found != null && found != path) {
          path = found;
          files = filePaths(s);
          // The server's or torrent's own name wins over the link's.
          yield MetaEvent(MediaMeta(title: p.basename(found)));
        }
        switch (s['status']) {
          case 'active' when s['seeder'] == 'true' && path != null:
            // Downloaded and now sharing: done for the queue, and aria2
            // keeps uploading until seed-time or the ratio runs out.
            _seeding[path] = gid;
            yield FileEvent(path);
            return;
          case 'active' || 'waiting':
            final progress = progressFrom(s);
            unawaited(_engine.trackFile(taskId,
                title: path == null ? null : p.basename(path),
                fraction: progress.fraction));
            yield ProgressEvent(progress);
          case 'complete':
            // A magnet's metadata, or a .torrent fetched over HTTP, hands
            // over to the real download under a new gid.
            final next = (s['followedBy'] as List?)?.firstOrNull;
            if (next == null) {
              yield FileEvent(path ?? '');
              return;
            }
            unawaited(_tryCall(settings, 'aria2.removeDownloadResult', [gid]));
            gid = _gids[taskId] = '$next';
          case 'error':
            throw failure(s['errorCode'], s['errorMessage']);
          case 'removed':
            for (final f in files) {
              await _deleteQuietly(f);
            }
            if (path != null) await _deleteQuietly('$path.aria2');
            throw const CancelledException();
          // 'paused': nothing moves; keep asking until resumed.
        }
        await Future<void>.delayed(pollInterval);
      }
    } finally {
      _gids.remove(taskId);
      unawaited(_engine.untrackFile(taskId));
      if (!_seeding.containsValue(gid)) {
        unawaited(_tryCall(settings, 'aria2.removeDownloadResult', [gid]));
      }
    }
  }

  /// The files inside a torrent or magnet, for picking some of them.
  /// aria2 fetches the metadata and pauses before downloading anything;
  /// [stopFiles] abandons the wait.
  Future<List<TorrentFile>> torrentFiles(
      String url, AppSettings settings) async {
    final dir = await _metadataDir();
    // A torrent aria2 is handed whole has its file list at once.
    final whole = url.startsWith('file:') || await _savedMetadata(url) != null;
    var gid = await _add(settings, url, {
      'dir': dir,
      if (whole) 'pause': 'true' else 'pause-metadata': 'true',
      // Kept for the real download, see _savedMetadata.
      'bt-save-metadata': 'true',
      'follow-torrent': 'mem',
      ..._proxy(settings),
    });
    _probes[url] = gid;
    try {
      if (whole) {
        final files = await _call(settings, 'aria2.getFiles', [gid]);
        return torrentFilesFrom(files as List, dir);
      }
      while (_probes[url] == gid) {
        final s = await _call(settings, 'aria2.tellStatus', [
          gid,
          ['status', 'followedBy', 'errorCode', 'errorMessage'],
        ]) as Map<String, dynamic>;
        switch (s['status']) {
          case 'error':
            throw failure(s['errorCode'], s['errorMessage']);
          case 'removed':
            throw const CancelledException();
          case 'complete':
            final next = (s['followedBy'] as List?)?.firstOrNull;
            if (next == null) {
              throw EngineException(EngineErrorKind.unknown,
                  raw: 'not a torrent');
            }
            unawaited(_tryCall(settings, 'aria2.removeDownloadResult', [gid]));
            gid = _probes[url] = '$next';
            final files = await _call(settings, 'aria2.getFiles', [gid]);
            return torrentFilesFrom(files as List, dir);
        }
        await Future<void>.delayed(pollInterval);
      }
      throw const CancelledException();
    } finally {
      if (_probes[url] == gid) _probes.remove(url);
      await _dropProbe(settings, gid);
    }
  }

  /// Stops [torrentFiles] for [url], if it is still waiting.
  Future<void> stopFiles(String url, AppSettings settings) async {
    final gid = _probes.remove(url);
    if (gid != null) await _dropProbe(settings, gid);
  }

  /// Removes a probe and waits until aria2 lets go of its info hash, or the
  /// real download of the same torrent would be refused as a duplicate.
  Future<void> _dropProbe(AppSettings settings, String gid) async {
    await _tryCall(settings, 'aria2.forceRemove', [gid]);
    for (var i = 0; i < 20; i++) {
      try {
        final s = await _call(settings, 'aria2.tellStatus', [gid, ['status']])
            as Map<String, dynamic>;
        if (s['status'] != 'active' && s['status'] != 'paused' &&
            s['status'] != 'waiting') {
          break;
        }
      } catch (_) {
        break;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    await _tryCall(settings, 'aria2.removeDownloadResult', [gid]);
  }

  /// Adds [url] to aria2 and returns its gid. A .torrent Snag keeps on disk,
  /// or a magnet's saved metadata, goes in by content: aria2 can't open
  /// file:// links, and a magnet need not ask peers for its metadata twice.
  Future<String> _add(
      AppSettings settings, String url, Map<String, String> options) async {
    final saved = await _savedMetadata(url);
    final torrent = url.startsWith('file:')
        ? await _readTorrent(url)
        : saved == null
            ? null
            : base64Encode(saved);
    return await (torrent != null
        ? _call(settings, 'aria2.addTorrent',
            [torrent, const <String>[], options])
        : _call(settings, 'aria2.addUri', [
            [url],
            options
          ])) as String;
  }

  static Future<String> _metadataDir() => getTemporaryDirectory().then(
      (d) => p.join(d.path, 'torrents'),
      onError: (_) => p.join(Directory.systemTemp.path, 'snag-torrents'));

  /// The .torrent aria2 saved while [torrentFiles] read a magnet.
  static Future<List<int>?> _savedMetadata(String url) async {
    if (!isMagnet(url)) return null;
    final hash = Uri.tryParse(url)?.queryParameters['xt']?.split(':').last;
    if (hash == null || hash.length != 40) return null;
    try {
      return await File(p.join(await _metadataDir(), '${hash.toLowerCase()}.torrent'))
          .readAsBytes();
    } catch (_) {
      return null;
    }
  }

  static Map<String, String> _proxy(AppSettings settings) {
    final proxy = settings.proxy?.trim() ?? '';
    return proxy.startsWith('http') ? {'all-proxy': proxy} : const {};
  }

  /// Stops uploading [path], e.g. before it is deleted; the files stay.
  Future<void> stopSharing(String path) async {
    final gid = _seeding.remove(path);
    final endpoint = _endpoint;
    if (gid == null || endpoint == null) return;
    try {
      await _post(await endpoint, 'aria2.forceRemove', [gid]);
    } catch (_) {} // Already done sharing.
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
      final state = await getApplicationSupportDirectory()
          .then<String?>((d) => d.path, onError: (_) => null);
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
        // Torrents: seed-time is set per download from Settings; keep the
        // DHT between runs for magnets.
        if (state != null) '--dht-file-path=${p.join(state, 'dht.dat')}',
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

  static Future<String> _readTorrent(String url) async {
    try {
      return base64Encode(await File.fromUri(Uri.parse(url)).readAsBytes());
    } on FileSystemException catch (e) {
      throw EngineException(EngineErrorKind.fileGone, details: '$e');
    }
  }

  static Future<void> _deleteQuietly(String path) async {
    try {
      await File(path).delete();
    } catch (_) {}
  }
}

/// Where a download lands: the file, or a multi-file torrent's folder.
/// Null until aria2 knows (a magnet still fetching its metadata).
String? resultPath(Map<String, dynamic> s) {
  final paths = filePaths(s);
  if (paths.isEmpty) return null;
  final name = ((s['bittorrent'] as Map?)?['info'] as Map?)?['name'];
  if (paths.length > 1 && name is String && name.isNotEmpty) {
    return p.join('${s['dir']}', name);
  }
  return paths.first;
}

/// The real files of a download, without aria2's metadata placeholders.
List<String> filePaths(Map<String, dynamic> s) => [
      for (final f in (s['files'] as List?) ?? const [])
        if ('${(f as Map)['path']}' case final path
            when path.isNotEmpty && !path.startsWith('[METADATA]'))
          path,
    ];

/// One file inside a torrent; [index] is what aria2's select-file takes.
typedef TorrentFile = ({int index, String path, int size});

/// An `aria2.getFiles` answer for a torrent saved under [dir], with paths
/// inside the torrent's own folder.
List<TorrentFile> torrentFilesFrom(List<Object?> files, String dir) {
  final paths = [
    for (final f in files) p.relative('${(f as Map)['path']}', from: dir)
  ];
  // A multi-file torrent keeps everything in one folder named after it.
  final strip = paths.length > 1;
  return [
    for (final (i, f) in files.indexed)
      (
        index: int.parse('${(f as Map)['index']}'),
        path: strip ? p.joinAll(p.split(paths[i]).skip(1)) : paths[i],
        size: int.tryParse('${f['length']}') ?? 0,
      ),
  ];
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
