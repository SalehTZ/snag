import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards community translations (lib/l10n/app_*.arb) so a pull request with
/// a typo fails CI with a clear message instead of breaking the build.
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

  final translations = dir
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'app_[\w-]+\.arb$').hasMatch(f.path))
      .where((f) => !f.path.endsWith('app_en.arb'))
      .toList();

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
    final locale = arb['@@locale'] as String?;

    group(name, () {
      test('declares its locale and native name', () {
        expect(locale, isNotNull, reason: 'add "@@locale": "<code>"');
        expect(name, 'app_$locale.arb',
            reason: '@@locale must match the file name');
        expect(arb['languageNativeName'], isA<String>(),
            reason: 'add "languageNativeName": "<your language, in itself>"');
        expect(arb['languageNativeName'], isNot(template['languageNativeName']));
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
