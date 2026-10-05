import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:url_launcher/url_launcher.dart';

/// OS integration: opening files, revealing them, links, share intents.
abstract final class PlatformActions {
  static const _android = MethodChannel('snag/platform');

  static bool get canRevealInFolder => !Platform.isAndroid;

  static Future<bool> openFile(String path) async {
    if (!await File(path).exists()) return false;
    if (Platform.isAndroid) {
      return await _android.invokeMethod<bool>('openFile', {'path': path}) ??
          false;
    }
    return launchUrl(Uri.file(path));
  }

  static Future<bool> revealInFolder(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('explorer', ['/select,', path]);
        return true;
      }
      if (Platform.isMacOS) {
        await Process.run('open', ['-R', path]);
        return true;
      }
      // Linux: ask the file manager to highlight the file, else open the dir.
      final r = await Process.run('dbus-send', [
        '--session',
        '--print-reply',
        '--dest=org.freedesktop.FileManager1',
        '/org/freedesktop/FileManager1',
        'org.freedesktop.FileManager1.ShowItems',
        'array:string:${Uri.file(path)}',
        'string:',
      ]);
      if (r.exitCode == 0) return true;
      return await launchUrl(Uri.file(p.dirname(path)));
    } catch (_) {
      return false;
    }
  }

  static Future<bool> openFolder(String dir) async {
    if (Platform.isAndroid) return false;
    return launchUrl(Uri.file(dir));
  }

  /// Android 13+ notification permission. True elsewhere.
  static Future<bool> notificationsAllowed() async {
    if (!Platform.isAndroid) return true;
    return await _android.invokeMethod<bool>('notificationsAllowed') ?? false;
  }

  static Future<bool> requestNotifications() async {
    if (!Platform.isAndroid) return true;
    return await _android.invokeMethod<bool>('requestNotifications') ?? false;
  }

  static Future<StorageStatus> storageStatus() async {
    if (!Platform.isAndroid) return const StorageStatus.desktop();
    final m = await _android.invokeMapMethod<String, Object?>('storageStatus');
    return StorageStatus.fromMap(m ?? const {});
  }

  /// Android 9/10: WRITE_EXTERNAL_STORAGE, needed even for Download/.
  static Future<bool> requestLegacyStorage() async {
    if (!Platform.isAndroid) return true;
    return await _android.invokeMethod<bool>('requestLegacyStorage') ?? false;
  }

  static Future<void> openLink(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  /// Text shared into the app ("Share > Snag" on Android).
  static Stream<String> sharedText() {
    if (!Platform.isAndroid) return const Stream.empty();
    final controller = StreamController<String>();
    _android.setMethodCallHandler((call) async {
      if (call.method == 'shared' && call.arguments is String) {
        controller.add(call.arguments as String);
      }
    });
    _android.invokeMethod<String>('initialShare').then((text) {
      if (text != null && text.isNotEmpty) controller.add(text);
    }).catchError((_) {});
    return controller.stream;
  }
}

/// What Snag may write to on this device.
class StorageStatus {
  const StorageStatus({
    this.android = true,
    required this.sdk,
    required this.needsLegacyPermission,
    required this.legacyGranted,
    required this.externalRoot,
  });

  const StorageStatus.desktop()
      : android = false,
        sdk = 0,
        needsLegacyPermission = false,
        legacyGranted = true,
        externalRoot = '';

  factory StorageStatus.fromMap(Map<String, Object?> m) => StorageStatus(
        sdk: m['sdk'] as int? ?? 0,
        needsLegacyPermission: m['needsLegacyPermission'] as bool? ?? false,
        legacyGranted: m['legacyGranted'] as bool? ?? true,
        externalRoot: m['externalRoot'] as String? ?? '/storage/emulated/0',
      );

  final bool android;
  final int sdk;
  final bool needsLegacyPermission;
  final bool legacyGranted;
  final String externalRoot;

  /// Android 11+ only lets apps without "All files access" (which Snag
  /// doesn't ask for) save inside these shared folders.
  bool isAllowedFolder(String dir) {
    if (!android || needsLegacyPermission) return true;
    final root = externalRoot.endsWith('/') ? externalRoot : '$externalRoot/';
    return ['Download', 'Documents'].any((d) {
      final base = '$root$d';
      return dir == base || dir.startsWith('$base/');
    });
  }
}

