import 'dart:convert';
import 'dart:io';

import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../engine/android_engine.dart';
import '../engine/binary_manager.dart';
import '../engine/desktop_engine.dart';
import '../engine/ytdlp_engine.dart';
import 'json_store.dart';
import 'records.dart';
import 'settings.dart';

/// Everything loaded from disk before the first frame, so the UI never
/// flashes an empty library or default theme.
class Bootstrap {
  Bootstrap({
    required this.prefs,
    required this.historyStore,
    required this.history,
    required this.templateStore,
    required this.templates,
    this.systemAccent,
  });

  final SharedPreferences prefs;
  final JsonListStore<HistoryItem> historyStore;
  final List<HistoryItem> history;
  final JsonListStore<CommandTemplate> templateStore;
  final List<CommandTemplate> templates;

  /// Wallpaper (Android 12+) or OS accent (desktop) color, if any.
  final Color? systemAccent;

  static Future<Bootstrap> load() async {
    final prefs = await SharedPreferences.getInstance();
    final historyStore = await JsonListStore.open<HistoryItem>('history',
        decode: HistoryItem.fromJson, encode: (h) => h.toJson());
    final templateStore = await JsonListStore.open<CommandTemplate>(
        'templates',
        decode: CommandTemplate.fromJson,
        encode: (t) => t.toJson());
    final history = await historyStore.load();
    var templates = await templateStore.load();
    if (templates.isEmpty && !prefs.containsKey(_templatesSeededKey)) {
      templates = [...CommandTemplate.defaults];
      templateStore.save(templates);
      await prefs.setBool(_templatesSeededKey, true);
    }
    return Bootstrap(
      systemAccent: await _systemAccent(),
      prefs: prefs,
      historyStore: historyStore,
      history: history,
      templateStore: templateStore,
      templates: templates,
    );
  }

  static const _templatesSeededKey = 'templatesSeeded';

  static Future<Color?> _systemAccent() async {
    try {
      final palette = await DynamicColorPlugin.getCorePalette();
      if (palette != null) return Color(palette.primary.get(40));
      return await DynamicColorPlugin.getAccentColor();
    } catch (_) {
      return null;
    }
  }
}

final bootstrapProvider =
    Provider<Bootstrap>((ref) => throw UnimplementedError('override in main'));

// ------------------------------------------------------------------ settings

class SettingsNotifier extends Notifier<AppSettings> {
  static const _key = 'settings.v1';

  @override
  AppSettings build() {
    final raw = ref.read(bootstrapProvider).prefs.getString(_key);
    if (raw == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, Object?>);
    } catch (_) {
      return const AppSettings();
    }
  }

  void update(AppSettings Function(AppSettings s) change) {
    state = change(state);
    ref.read(bootstrapProvider).prefs.setString(_key, jsonEncode(state.toJson()));
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

// ------------------------------------------------------------------ engine

final isDesktop = Platform.isLinux || Platform.isWindows || Platform.isMacOS;

final binaryManagerProvider = Provider<BinaryManager>((ref) => BinaryManager());

final engineProvider = Provider<YtDlpEngine>((ref) {
  if (Platform.isAndroid) return AndroidEngine();
  return DesktopEngine(ref.watch(binaryManagerProvider));
});

// ------------------------------------------------------------------ history

class HistoryNotifier extends Notifier<List<HistoryItem>> {
  @override
  List<HistoryItem> build() => ref.read(bootstrapProvider).history;

  void _commit(List<HistoryItem> items) {
    state = items;
    ref.read(bootstrapProvider).historyStore.save(items);
  }

  void add(HistoryItem item) => _commit([item, ...state]);

  void remove(String id) => _commit(state.where((h) => h.id != id).toList());

  void clear() => _commit(const []);
}

final historyProvider =
    NotifierProvider<HistoryNotifier, List<HistoryItem>>(HistoryNotifier.new);

// ------------------------------------------------------------------ templates

class TemplatesNotifier extends Notifier<List<CommandTemplate>> {
  @override
  List<CommandTemplate> build() => ref.read(bootstrapProvider).templates;

  void _commit(List<CommandTemplate> items) {
    state = items;
    ref.read(bootstrapProvider).templateStore.save(items);
  }

  void upsert(CommandTemplate t) {
    final exists = state.any((e) => e.id == t.id);
    _commit(exists
        ? [for (final e in state) e.id == t.id ? t : e]
        : [...state, t]);
  }

  void remove(String id) => _commit(state.where((t) => t.id != id).toList());
}

final templatesProvider =
    NotifierProvider<TemplatesNotifier, List<CommandTemplate>>(
        TemplatesNotifier.new);
