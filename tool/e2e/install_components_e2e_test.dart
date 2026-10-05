// ignore_for_file: invalid_use_of_visible_for_testing_member
// Downloads and unpacks the real ffmpeg and Deno builds (~150 MB total).
//
//   flutter test tool/e2e/install_components_e2e_test.dart
@Tags(['e2e'])
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:snag/engine/binary_manager.dart';

class TempPaths extends PathProviderPlatform with MockPlatformInterfaceMixin {
  TempPaths(this.root);
  final String root;
  @override
  Future<String?> getApplicationSupportPath() async => '$root/support';
}

void main() {
  late Directory root;
  late BinaryManager bins;

  setUpAll(() {
    root = Directory.systemTemp.createTempSync('snag-install');
    PathProviderPlatform.instance = TempPaths(root.path);
    bins = BinaryManager();
  });

  tearDownAll(() => root.deleteSync(recursive: true));

  for (final c in [Component.deno, Component.ffmpeg]) {
    test('installs ${c.label} and leaves only the binaries behind', () async {
      await bins.install(c);
      final status = await bins.withVersion(await bins.resolve(c));
      expect(status.source, ComponentSource.managed);
      expect(status.version, isNotNull);
      // ignore: avoid_print
      print('${c.label} ${status.version}');
      final leftovers = (await bins.binDir())
          .listSync()
          .map((e) => e.uri.pathSegments.where((s) => s.isNotEmpty).last)
          .where((n) => !{'deno', 'ffmpeg', 'ffprobe'}.contains(n.replaceAll('.exe', '')))
          .toList();
      expect(leftovers, isEmpty, reason: 'archives and scratch dirs are cleaned up');
      if (c == Component.ffmpeg) {
        expect(File('${(await bins.binDir()).path}/ffprobe').existsSync(), isTrue);
      }
    }, timeout: const Timeout(Duration(minutes: 15)));
  }
}
