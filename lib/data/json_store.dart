import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// A tiny durable list store: one JSON file, atomic writes (temp + rename),
/// coalesced saves. Plenty for thousands of history rows, zero native deps.
class JsonListStore<T> {
  JsonListStore._(this._file, this._decode, this._encode);

  final File _file;
  final T Function(Map<String, dynamic>) _decode;
  final Map<String, Object?> Function(T) _encode;
  Timer? _pending;
  List<T> _latest = const [];

  /// A store backed by an explicit file (tests, custom locations).
  factory JsonListStore.at(
    File file, {
    required T Function(Map<String, dynamic>) decode,
    required Map<String, Object?> Function(T) encode,
  }) =>
      JsonListStore._(file, decode, encode);

  static Future<JsonListStore<T>> open<T>(
    String name, {
    required T Function(Map<String, dynamic>) decode,
    required Map<String, Object?> Function(T) encode,
  }) async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    return JsonListStore._(File(p.join(dir.path, '$name.json')), decode, encode);
  }

  Future<List<T>> load() async {
    try {
      if (!await _file.exists()) return [];
      final raw = jsonDecode(await _file.readAsString());
      if (raw is! List) return [];
      final items = <T>[];
      for (final e in raw) {
        if (e is! Map<String, dynamic>) continue;
        try {
          items.add(_decode(e));
        } catch (_) {
          // Skip a corrupt row rather than losing the whole file.
        }
      }
      return _latest = items;
    } catch (_) {
      // Keep the unreadable file around for manual recovery.
      try {
        await _file.rename('${_file.path}.corrupt');
      } catch (_) {}
      return [];
    }
  }

  void save(List<T> items) {
    _latest = items;
    _pending?.cancel();
    _pending = Timer(const Duration(milliseconds: 300), flush);
  }

  Future<void> flush() async {
    _pending?.cancel();
    _pending = null;
    final tmp = File('${_file.path}.tmp');
    await tmp.writeAsString(jsonEncode(_latest.map(_encode).toList()));
    await tmp.rename(_file.path);
  }
}
