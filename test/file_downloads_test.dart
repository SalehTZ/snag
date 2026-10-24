import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:snag/core/format.dart';
import 'package:snag/data/settings.dart';
import 'package:snag/engine/args_builder.dart';
import 'package:snag/engine/aria2.dart';
import 'package:snag/engine/file_probe.dart';
import 'package:snag/engine/models.dart';
import 'package:snag/engine/output_parser.dart';
import 'package:snag/engine/ytdlp_engine.dart';

class _Engine extends YtDlpEngine {
  final started = <List<String>>[];
  @override
  bool get allowsBrowserCookies => false;
  @override
  Future<ToolPaths> toolPaths(AppSettings settings) async => const ToolPaths();
  @override
  Future<String> defaultDownloadDir() async => '/tmp';
  @override
  Future<String> runToString(List<String> args, AppSettings settings) async =>
      '';
  @override
  Stream<String> runLines(List<String> a, AppSettings s, String id) =>
      const Stream.empty();
  @override
  Future<void> cancel(String taskId) async {}
  @override
  Future<void> startAria2(List<String> args, AppSettings settings) async =>
      started.add(args);
  @override
  Future<String?> version(AppSettings settings) async => null;
  @override
  Future<UpdateResult> update(AppSettings settings) async =>
      const UpdateResult(changed: false);
}

/// An aria2 RPC that answers tellStatus from [statuses], one per call.
MockClient _rpc(List<Map<String, Object?>> statuses, List<String> calls) =>
    MockClient((req) async {
      final body = jsonDecode(req.body) as Map<String, dynamic>;
      final method = body['method'] as String;
      calls.add(method);
      final result = switch (method) {
        'aria2.addUri' => 'gid1',
        'aria2.tellStatus' => statuses.removeAt(0),
        _ => 'OK',
      };
      return http.Response(jsonEncode({'id': 'snag', 'result': result}), 200);
    });

void main() {
  group('file links', () {
    test('extensions that name a file', () {
      expect(looksLikeFile('https://x.org/dl/app-1.2.apk'), isTrue);
      expect(looksLikeFile('https://x.org/a/B.ZIP?token=1'), isTrue);
      expect(looksLikeFile('https://youtube.com/watch?v=1'), isFalse);
      expect(looksLikeFile('https://x.org/video.mp4'), isFalse);
    });

    test('file name from Content-Disposition', () {
      expect(fileNameFrom('attachment; filename="report 2026.pdf"'),
          'report 2026.pdf');
      expect(fileNameFrom("attachment; filename*=UTF-8''na%C3%AFve.zip"),
          'naïve.zip');
      // A server must not pick a path outside the download folder.
      expect(fileNameFrom('attachment; filename="../../.bashrc"'), '.bashrc');
      expect(fileNameFrom('inline'), isNull);
    });

    test('headers: a web page is not a file', () {
      expect(
          fileFromHeaders('https://x.org/', {'content-type': 'text/html'}),
          isNull);
    });

    test('headers: size from a range answer, name from the URL', () {
      final f = fileFromHeaders('https://dl.x.org/files/linux.iso', {
        'content-type': 'application/octet-stream',
        'content-range': 'bytes 0-0/4321',
      })!;
      expect(f.name, 'linux.iso');
      expect(f.size, 4321);
      expect(f.host, 'dl.x.org');
    });

    test('spec round-trips its kind; old records are media', () {
      const spec = DownloadSpec(url: 'u', kind: DownloadKind.file);
      expect(DownloadSpec.fromJson(spec.toJson()).kind, DownloadKind.file);
      expect(DownloadSpec.fromJson({'url': 'u'}).kind, DownloadKind.media);
    });
  });

  group('torrents', () {
    const magnet = 'magnet:?xt=urn:btih:ABC123&dn=Big%20Buck%20Bunny&xl=276445467'
        '&tr=udp%3A%2F%2Ftracker.example%3A80';

    test('magnet links are found in shared text and describe themselves', () {
      expect(extractUrl('grab this: $magnet thanks'), magnet);
      final f = magnetFile(magnet);
      expect(f.name, 'Big Buck Bunny');
      expect(f.size, 276445467);
      expect(f.host, '');
      expect(isTorrent(magnet), isTrue);
      expect(isTorrent('https://x.org/a.torrent'), isTrue);
      expect(isTorrent('https://x.org/a.zip'), isFalse);
    });

    test('result path: a multi-file torrent lands in its folder', () {
      final s = {
        'dir': '/d',
        'bittorrent': {
          'info': {'name': 'Album'}
        },
        'files': [
          {'path': '/d/Album/01.flac'},
          {'path': '/d/Album/02.flac'},
        ],
      };
      expect(resultPath(s), '/d/Album');
      expect(resultPath({
        'files': [
          {'path': '[METADATA]ABC123'}
        ]
      }), isNull);
    });

    test('a magnet hands over from its metadata to the real download',
        () async {
      final calls = <String>[];
      final aria2 = Aria2(_Engine(),
          client: _rpc([
            {
              'status': 'complete',
              'files': [
                {'path': '[METADATA]ABC123'}
              ],
              'followedBy': ['gid2'],
            },
            {
              'status': 'complete',
              'dir': '/d',
              'files': [
                {'path': '/d/Big Buck Bunny.mp4'}
              ],
            },
          ], calls));
      Aria2.pollInterval = Duration.zero;

      final events = await aria2
          .download(
            spec: const DownloadSpec(url: magnet, kind: DownloadKind.file),
            settings: const AppSettings(),
            outputDir: '/d',
            taskId: 't3',
          )
          .toList();

      expect(events.whereType<FileEvent>().single.path, '/d/Big Buck Bunny.mp4');
      expect(calls.where((c) => c == 'aria2.tellStatus'), hasLength(2));
    });
  });

  group('picking files in a torrent', () {
    test('paths inside the torrent folder, with aria2 indexes', () {
      final files = torrentFilesFrom([
        {'index': '1', 'path': '/tmp/t/Album/01.flac', 'length': '30'},
        {'index': '2', 'path': '/tmp/t/Album/art/cover.jpg', 'length': '5'},
      ], '/tmp/t');
      expect(files.map((f) => f.path), ['01.flac', 'art/cover.jpg']);
      expect(files.map((f) => f.index), [1, 2]);
      expect(files.first.size, 30);
      expect(torrentFilesFrom([
        {'index': '1', 'path': '/tmp/t/one.iso', 'length': '9'}
      ], '/tmp/t').single.path, 'one.iso');
    });

    test('reads the list from the paused download and lets go of it',
        () async {
      final calls = <(String, List<Object?>)>[];
      final aria2 = Aria2(_Engine(), client: MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final method = body['method'] as String;
        final params = (body['params'] as List).skip(1).toList();
        calls.add((method, params));
        final result = switch (method) {
          'aria2.addUri' => 'gid1',
          // The probe's cleanup asks only for the status.
          'aria2.tellStatus' when (params[1] as List).length == 1 =>
            {'status': 'removed'},
          'aria2.tellStatus' => {'status': 'complete', 'followedBy': ['gid2']},
          'aria2.getFiles' => [
              {'index': '1', 'path': 'x', 'length': '1'},
              {'index': '2', 'path': 'y', 'length': '2'},
            ],
          _ => 'OK',
        };
        return http.Response(jsonEncode({'id': 'snag', 'result': result}), 200);
      }));
      Aria2.pollInterval = Duration.zero;

      final files = await aria2.torrentFiles(
          'https://x.org/a.torrent', const AppSettings());

      expect(files.map((f) => f.index), [1, 2]);
      final add = calls.firstWhere((c) => c.$1 == 'aria2.addUri').$2;
      expect(add[1], containsPair('pause-metadata', 'true'));
      expect(calls.where((c) => c.$1 == 'aria2.getFiles').single.$2, ['gid2']);
      expect(
          calls.where((c) => c.$1 == 'aria2.forceRemove').single.$2, ['gid2']);
    });

    test('the download fetches only the picked files', () async {
      Map<String, dynamic>? options;
      final aria2 = Aria2(_Engine(), client: MockClient((req) async {
        final body = jsonDecode(req.body) as Map<String, dynamic>;
        final result = switch (body['method']) {
          'aria2.addUri' => () {
              options = (body['params'] as List)[2] as Map<String, dynamic>;
              return 'gid1';
            }(),
          'aria2.tellStatus' => {
              'status': 'complete',
              'dir': '/d',
              'files': [
                {'path': '/d/a.mkv'}
              ],
            },
          _ => 'OK',
        };
        return http.Response(jsonEncode({'id': 'snag', 'result': result}), 200);
      }));

      await aria2
          .download(
            spec: const DownloadSpec(
                url: 'https://x.org/a.torrent',
                kind: DownloadKind.file,
                files: [1, 3]),
            settings: const AppSettings(),
            outputDir: '/d',
            taskId: 't4',
          )
          .toList();

      expect(options, containsPair('select-file', '1,3'));
      const spec = DownloadSpec(url: 'u', files: [1, 3]);
      expect(DownloadSpec.fromJson(spec.toJson()).files, [1, 3]);
      expect(DownloadSpec.fromJson({'url': 'u'}).files, isNull);
    });
  });

  group('aria2', () {
    test('status as progress', () {
      final p = progressFrom({
        'totalLength': '1000',
        'completedLength': '250',
        'downloadSpeed': '50',
      });
      expect(p.fraction, 0.25);
      expect(p.eta, 15);
      expect(progressFrom({'totalLength': '0', 'completedLength': '0'}).total,
          isNull);
    });

    test('exit codes in Snag terms', () {
      expect(failure('3', 'Resource not found').kind, EngineErrorKind.fileGone);
      expect(failure(6, 'Network problem').kind, EngineErrorKind.network);
      expect(failure('9', 'No space').kind, EngineErrorKind.folderNotWritable);
      expect(failure('1', 'odd').raw, 'odd');
    });

    test('downloads a file and reports its real name and path', () async {
      final calls = <String>[];
      final engine = _Engine();
      final aria2 = Aria2(engine,
          client: _rpc([
            {
              'status': 'complete',
              'totalLength': '10',
              'completedLength': '10',
              'downloadSpeed': '0',
              'files': [
                {'path': '/tmp/Snag/real-name.zip'}
              ],
            },
          ], calls));

      final events = await aria2
          .download(
            spec: const DownloadSpec(url: 'https://x.org/f', kind: DownloadKind.file),
            settings: const AppSettings(connections: 4),
            outputDir: '/tmp/Snag',
            taskId: 't1',
          )
          .toList();

      expect(events.whereType<MetaEvent>().single.meta.title, 'real-name.zip');
      expect(events.whereType<FileEvent>().single.path,
          '/tmp/Snag/real-name.zip');
      expect(engine.started.single, contains('--stop-with-process=$pid'));
      expect(calls, containsAllInOrder(
          ['aria2.getVersion', 'aria2.addUri', 'aria2.tellStatus']));
    });

    test('a removed download is a cancel and leaves no partial file',
        () async {
      final dir = await Directory.systemTemp.createTemp('snag');
      final part = File('${dir.path}/big.iso')..writeAsStringSync('x');
      final control = File('${part.path}.aria2')..writeAsStringSync('x');
      final aria2 = Aria2(_Engine(),
          client: _rpc([
            {
              'status': 'removed',
              'files': [
                {'path': part.path}
              ],
            },
          ], []));

      await expectLater(
        aria2.download(
          spec: const DownloadSpec(url: 'https://x.org/f', kind: DownloadKind.file),
          settings: const AppSettings(),
          outputDir: dir.path,
          taskId: 't2',
        ),
        emitsThrough(emitsError(isA<CancelledException>())),
      );
      expect(part.existsSync(), isFalse);
      expect(control.existsSync(), isFalse);
      await dir.delete(recursive: true);
    });
  });
}
