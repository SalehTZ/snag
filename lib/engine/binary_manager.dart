import 'dart:async';
import 'dart:ffi' show Abi;
import 'dart:io';
import 'dart:isolate';

import 'package:archive/archive_io.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

enum Component {
  ytDlp('yt-dlp', 'The download engine. Required.'),
  ffmpeg('ffmpeg', 'Merges video with audio and converts formats.'),
  deno('Deno', 'JavaScript runtime that YouTube now requires.');

  const Component(this.label, this.purpose);
  final String label;
  final String purpose;
}

enum ComponentSource { managed, system, custom, missing }

class ComponentStatus {
  const ComponentStatus(this.component, this.source, {this.path, this.version});
  final Component component;
  final ComponentSource source;
  final String? path;
  final String? version;

  bool get available => source != ComponentSource.missing;
}

/// Download progress for a component install: 0..1, or null if unknown.
typedef InstallProgress = void Function(double? fraction, String stage);

/// Finds, downloads and updates the desktop helper binaries. Everything lives
/// in `<app support>/bin`, so nothing touches system directories.
class BinaryManager {
  BinaryManager({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  Directory? _binDir;

  static String get _exe => Platform.isWindows ? '.exe' : '';

  Future<Directory> binDir() async {
    if (_binDir != null) return _binDir!;
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'bin'));
    await dir.create(recursive: true);
    return _binDir = dir;
  }

  Future<String> managedPath(Component c) async {
    final dir = (await binDir()).path;
    return switch (c) {
      Component.ytDlp => p.join(dir, 'yt-dlp$_exe'),
      Component.ffmpeg => p.join(dir, 'ffmpeg$_exe'),
      Component.deno => p.join(dir, 'deno$_exe'),
    };
  }

  /// Resolution order: user override, then Snag-managed copy, then PATH.
  Future<ComponentStatus> resolve(Component c, {String? override}) async {
    if (override != null && override.trim().isNotEmpty) {
      final exists = await File(override).exists();
      return ComponentStatus(
          c, exists ? ComponentSource.custom : ComponentSource.missing,
          path: exists ? override : null);
    }
    final managed = await managedPath(c);
    if (await File(managed).exists()) {
      return ComponentStatus(c, ComponentSource.managed, path: managed);
    }
    final system = await _which(switch (c) {
      Component.ytDlp => 'yt-dlp',
      Component.ffmpeg => 'ffmpeg',
      Component.deno => 'deno',
    });
    if (system != null) {
      return ComponentStatus(c, ComponentSource.system, path: system);
    }
    return ComponentStatus(c, ComponentSource.missing);
  }

  Future<ComponentStatus> withVersion(ComponentStatus s) async {
    if (s.path == null) return s;
    final args = s.component == Component.ytDlp ? ['--version'] : ['-version'];
    final realArgs = s.component == Component.deno ? ['--version'] : args;
    try {
      final r = await Process.run(s.path!, realArgs)
          .timeout(const Duration(seconds: 15));
      final first = '${r.stdout}'.trim().split('\n').first;
      final version = switch (s.component) {
        Component.ytDlp => first,
        Component.ffmpeg =>
          RegExp(r'ffmpeg version (\S+)').firstMatch(first)?.group(1) ?? first,
        Component.deno =>
          RegExp(r'deno (\S+)').firstMatch(first)?.group(1) ?? first,
      };
      return ComponentStatus(s.component, s.source,
          path: s.path, version: version);
    } catch (_) {
      return s;
    }
  }

  // ---------------------------------------------------------------- install

  Future<void> install(Component c, {InstallProgress? onProgress}) async {
    switch (c) {
      case Component.ytDlp:
        final target = await managedPath(c);
        await _download(Uri.parse(_ytDlpUrl()), target, onProgress);
        await _makeExecutable(target);
      case Component.deno:
        final archive = p.join((await binDir()).path, 'deno.zip');
        await _download(Uri.parse(_denoUrl()), archive, onProgress);
        await _extractPicking(archive, {'deno$_exe'}, onProgress);
      case Component.ffmpeg:
        await _installFfmpeg(onProgress);
    }
  }

  Future<void> _installFfmpeg(InstallProgress? onProgress) async {
    final dir = (await binDir()).path;
    final wanted = {'ffmpeg$_exe', 'ffprobe$_exe'};
    if (Platform.isMacOS) {
      // Static builds ship ffmpeg and ffprobe as separate zips.
      final arch = Abi.current() == Abi.macosArm64 ? 'arm64' : 'amd64';
      for (final tool in ['ffmpeg', 'ffprobe']) {
        final archive = p.join(dir, '$tool.zip');
        await _download(
          Uri.parse('https://ffmpeg.martin-riedl.de/redirect/latest/macos/'
              '$arch/release/$tool.zip'),
          archive,
          onProgress,
          label: 'Downloading $tool',
        );
        await _extractPicking(archive, {tool}, onProgress);
      }
      return;
    }
    final asset = switch (Abi.current()) {
      Abi.linuxArm64 => 'ffmpeg-master-latest-linuxarm64-gpl.tar.xz',
      Abi.windowsArm64 => 'ffmpeg-master-latest-winarm64-gpl.zip',
      _ when Platform.isWindows => 'ffmpeg-master-latest-win64-gpl.zip',
      _ => 'ffmpeg-master-latest-linux64-gpl.tar.xz',
    };
    final archive = p.join(dir, asset);
    await _download(
      Uri.parse('https://github.com/yt-dlp/FFmpeg-Builds/releases/download/'
          'latest/$asset'),
      archive,
      onProgress,
    );
    await _extractPicking(archive, wanted, onProgress);
  }

  /// yt-dlp can update itself in place when it is the standalone binary.
  Future<String> updateYtDlp(String path, {bool nightly = false}) async {
    final r = await Process.run(
      path,
      ['--update-to', nightly ? 'nightly' : 'stable'],
      environment: _utf8Env,
    ).timeout(const Duration(minutes: 3));
    final out = '${r.stdout}\n${r.stderr}'.trim();
    if (r.exitCode != 0) throw Exception(out);
    final line = out
        .split('\n')
        .lastWhere((l) => l.trim().isNotEmpty, orElse: () => out);
    return line.trim();
  }

  static const _utf8Env = {'PYTHONIOENCODING': 'utf-8', 'PYTHONUTF8': '1'};

  // ---------------------------------------------------------------- helpers

  String _ytDlpUrl() {
    const base = 'https://github.com/yt-dlp/yt-dlp/releases/latest/download';
    final asset = switch (Abi.current()) {
      Abi.windowsX64 || Abi.windowsArm64 => 'yt-dlp.exe',
      Abi.windowsIA32 => 'yt-dlp_x86.exe',
      Abi.macosArm64 || Abi.macosX64 => 'yt-dlp_macos',
      Abi.linuxArm64 => 'yt-dlp_linux_aarch64',
      Abi.linuxArm => 'yt-dlp_linux_armv7l',
      _ => 'yt-dlp_linux',
    };
    return '$base/$asset';
  }

  String _denoUrl() {
    const base = 'https://github.com/denoland/deno/releases/latest/download';
    final target = switch (Abi.current()) {
      Abi.windowsX64 || Abi.windowsArm64 => 'x86_64-pc-windows-msvc',
      Abi.macosArm64 => 'aarch64-apple-darwin',
      Abi.macosX64 => 'x86_64-apple-darwin',
      Abi.linuxArm64 => 'aarch64-unknown-linux-gnu',
      _ => 'x86_64-unknown-linux-gnu',
    };
    return '$base/deno-$target.zip';
  }

  Future<void> _download(Uri uri, String target, InstallProgress? onProgress,
      {String label = 'Downloading'}) async {
    final tmp = File('$target.part');
    final response = await _client.send(http.Request('GET', uri));
    if (response.statusCode != 200) {
      throw HttpException('HTTP ${response.statusCode} for $uri', uri: uri);
    }
    final total = response.contentLength;
    var received = 0;
    final sink = tmp.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(
            total != null && total > 0 ? received / total : null, label);
      }
    } finally {
      await sink.close();
    }
    final dest = File(target);
    if (await dest.exists()) await dest.delete();
    await tmp.rename(target);
  }

  /// Extracts [archivePath] in a background isolate, keeps only files whose
  /// basename is in [wanted] (placed flat in the bin dir), deletes the rest.
  Future<void> _extractPicking(String archivePath, Set<String> wanted,
      InstallProgress? onProgress) async {
    onProgress?.call(null, 'Unpacking');
    final dir = (await binDir()).path;
    final scratch = p.join(dir, '.extract-${DateTime.now().microsecondsSinceEpoch}');
    try {
      await Isolate.run(() => extractFileToDisk(archivePath, scratch));
      final found = <String>{};
      await for (final e in Directory(scratch).list(recursive: true)) {
        if (e is! File) continue;
        final name = p.basename(e.path);
        if (wanted.contains(name) && !found.contains(name)) {
          final dest = p.join(dir, name);
          if (await File(dest).exists()) await File(dest).delete();
          await e.copy(dest);
          await _makeExecutable(dest);
          found.add(name);
        }
      }
      final missing = wanted.difference(found);
      if (missing.isNotEmpty) {
        throw Exception('Archive did not contain ${missing.join(', ')}');
      }
    } finally {
      await _tryDelete(Directory(scratch));
      await _tryDelete(File(archivePath));
    }
  }

  Future<void> _makeExecutable(String path) async {
    if (Platform.isWindows) return;
    await Process.run('chmod', ['+x', path]);
    if (Platform.isMacOS) {
      // Downloaded binaries get quarantined by Gatekeeper.
      await Process.run('xattr', ['-d', 'com.apple.quarantine', path]);
    }
  }

  Future<void> _tryDelete(FileSystemEntity e) async {
    try {
      if (await e.exists()) await e.delete(recursive: true);
    } catch (_) {}
  }

  static Future<String?> _which(String name) async {
    final paths = (Platform.environment['PATH'] ?? '')
        .split(Platform.isWindows ? ';' : ':')
        .where((d) => d.isNotEmpty)
        .toList();
    // GUI apps on macOS/Linux often start with a minimal PATH.
    if (!Platform.isWindows) {
      paths.addAll([
        '/usr/local/bin',
        '/usr/bin',
        '/opt/homebrew/bin',
        '${Platform.environment['HOME']}/.local/bin',
        '${Platform.environment['HOME']}/.deno/bin',
      ]);
    }
    for (final dir in paths) {
      final candidate = p.join(dir, '$name$_exe');
      if (await File(candidate).exists()) return candidate;
    }
    return null;
  }
}
