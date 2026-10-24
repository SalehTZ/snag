import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
