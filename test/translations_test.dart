import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards community translations (lib/l10n/app_*.arb) so a pull request with
/// a typo fails CI with a clear message instead of breaking the build.
///
/// Files may come from Weblate, which leaves out "@@locale" (gen-l10n then
/// takes the locale from the file name), copies the "@key" notes from the
/// English file, and writes only the strings someone has translated.
void main() {
  final dir = Directory('lib/l10n');
  Map<String, dynamic> load(File f) =>
      jsonDecode(f.readAsStringSync()) as Map<String, dynamic>;

  final template = load(File('${dir.path}/app_en.arb'));
  final messageKeys =
      template.keys.where((k) => !k.startsWith('@')).toSet();

  /// Languages that ship complete. Others may be partial: untranslated
  /// strings fall back to English.
  const complete = {'fa'};

  final fileName = RegExp(r'^app_([A-Za-z]+(?:_[A-Za-z0-9]+)*)\.arb$');
  final translations = dir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.arb'))
      .where((f) => !f.path.endsWith('app_en.arb'))
      .toList();
  final locales = {
    for (final f in translations)
      fileName.firstMatch(f.uri.pathSegments.last)?.group(1),
  };

  Set<String> placeholdersOf(String message) {
    // Top-level {name} and plural/select arguments, ignoring ICU branches.
    final names = <String>{};
    for (final m in RegExp(r'\{(\w+)(?:,|\})').allMatches(message)) {
      names.add(m.group(1)!);
    }
    return names..removeAll({'other', 'one', 'few', 'many', 'zero', 'two'});
  }

  test('there is at least one translation', () {
    expect(translations, isNotEmpty);
  });

  for (final file in translations) {
    final name = file.uri.pathSegments.last;
    final arb = load(file);
    final locale = fileName.firstMatch(name)?.group(1);

    group(name, () {
      test('is named after its locale', () {
        expect(locale, isNotNull,
            reason: 'name the file app_<code>.arb, e.g. app_de.arb or '
                'app_pt_BR.arb');
        final declared = arb['@@locale'];
        if (declared != null) {
          expect(declared, locale,
              reason: '"@@locale" must match the file name');
        }
      });

      test('has a base language file', () {
        // gen-l10n refuses app_pt_BR.arb without app_pt.arb.
        if (locale == null) return;
        final base = locale.split('_').first;
        expect(base == locale || locales.contains(base), isTrue,
            reason: 'add app_$base.arb first: regional and script variants '
                'only hold the strings that differ from the base language');
      });

      test('names its language in itself', () {
        final native = arb['languageNativeName'];
        if (native == null) return; // The picker shows the code meanwhile.
        expect(native, isNot(template['languageNativeName']),
            reason: '"languageNativeName" is this language\'s own name, '
                'e.g. "Deutsch", not "English"');
      });

      test('has no blank strings', () {
        final blank = arb.entries
            .where((e) => !e.key.startsWith('@') && e.value is String)
            .where((e) => (e.value as String).trim().isEmpty)
            .map((e) => e.key)
            .toList();
        expect(blank, isEmpty,
            reason: 'blank strings show as empty text; leave them out so '
                'they fall back to English');
      });

      test('has no unknown keys', () {
        final unknown = arb.keys
            .where((k) => !k.startsWith('@'))
            .where((k) => !messageKeys.contains(k))
            .toList();
        expect(unknown, isEmpty,
            reason: 'these keys do not exist in app_en.arb (typo?)');
      });

      test('keeps every placeholder', () {
        final broken = <String>[];
        for (final key in arb.keys.where((k) => !k.startsWith('@'))) {
          final expected = placeholdersOf(template[key] as String);
          final actual = placeholdersOf(arb[key] as String);
          if (!actual.containsAll(expected)) {
            broken.add('$key: expected ${expected.join(', ')}');
          }
        }
        expect(broken, isEmpty,
            reason: 'translate the words around {placeholders}, '
                'but keep the {names} themselves');
      });

      test('has balanced braces', () {
        final bad = arb.entries
            .where((e) => !e.key.startsWith('@') && e.value is String)
            .where((e) {
          final s = e.value as String;
          return '{'.allMatches(s).length != '}'.allMatches(s).length;
        }).map((e) => e.key);
        expect(bad, isEmpty);
      });

      if (complete.contains(locale)) {
        test('is complete', () {
          final missing = messageKeys.difference(arb.keys.toSet()).toList()
            ..sort();
          expect(missing, isEmpty);
        });
      }
    });
  }
}
