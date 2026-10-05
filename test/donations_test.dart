import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:snag/core/app_info.dart';

/// Donation addresses appear in the app and in every README; a typo in any
/// copy sends someone's money into the void. Keep them identical.
void main() {
  final readmes = Directory('.')
      .listSync()
      .whereType<File>()
      .where((f) => RegExp(r'README(\.\w+)?\.md$').hasMatch(f.path))
      .toList();

  test('there are READMEs to check', () {
    expect(readmes.length, greaterThanOrEqualTo(2));
  });

  for (final readme in readmes) {
    final text = readme.readAsStringSync();
    final name = readme.uri.pathSegments.last;

    test('$name lists every wallet from AppInfo', () {
      for (final w in AppInfo.wallets) {
        expect(text, contains(w.address), reason: '${w.network} in $name');
      }
    });

    test('$name has no placeholder addresses', () {
      expect(text, isNot(contains('YOUR_')));
    });

    test('$name has no address that the app does not know', () {
      final known = AppInfo.wallets.map((w) => w.address).toSet();
      final found = RegExp(r'`((?:0x[0-9a-fA-F]{40})|(?:T[1-9A-HJ-NP-Za-km-z]{33})|(?:bc1[02-9ac-hj-np-z]{11,71}))`')
          .allMatches(text)
          .map((m) => m.group(1)!);
      expect(found.toSet().difference(known), isEmpty);
    });
  }
}
