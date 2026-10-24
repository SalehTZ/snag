import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snag/data/json_store.dart';
import 'package:snag/data/providers.dart';
import 'package:snag/data/records.dart';
import 'package:snag/engine/aria2.dart';
import 'package:snag/engine/models.dart';
import 'package:snag/engine/ytdlp_engine.dart';
import 'package:snag/features/library/library_screen.dart';
import 'package:snag/l10n/l10n.dart';

class _NoEngine implements YtDlpEngine {
  @override
  dynamic noSuchMethod(Invocation i) => throw UnimplementedError();
}

class _Sharing extends Aria2 {
  _Sharing(this.path) : super(_NoEngine());
  final String path;
  @override
  ValueListenable<Map<String, String>> get seeding =>
      ValueNotifier({path: 'gid'});
}

void main() {
  testWidgets('clearing the library keeps files and sharing torrents', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final dir = Directory.systemTemp.createTempSync('snag-clear');
    final file = File('${dir.path}/a.mp4')..writeAsStringSync('x');
    HistoryItem item(String id, String path, int minutesAgo) => HistoryItem(
      id: id,
      spec: DownloadSpec(url: 'https://example.com/$id'),
      meta: MediaMeta(title: 'Item $id'),
      finishedAt: DateTime.now().subtract(Duration(minutes: minutesAgo)),
      filePath: path,
    );
    final bootstrap = Bootstrap(
      prefs: await SharedPreferences.getInstance(),
      historyStore: JsonListStore.at(
        File('${dir.path}/h.json'),
        decode: HistoryItem.fromJson,
        encode: (h) => h.toJson(),
      ),
      history: [item('a', file.path, 1), item('b', '/b.mp4', 2)],
      templateStore: JsonListStore.at(
        File('${dir.path}/t.json'),
        decode: CommandTemplate.fromJson,
        encode: (t) => t.toJson(),
      ),
      templates: const [],
    );
    final container = ProviderContainer(
      overrides: [
        bootstrapProvider.overrideWithValue(bootstrap),
        aria2Provider.overrideWithValue(_Sharing('/b.mp4')),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: LibraryScreen(),
        ),
      ),
    );
    List<String> ids() => [
      for (final h in container.read(historyProvider)) h.id,
    ];

    await tester.tap(find.text('Clear list'));
    await tester.pumpAndSettle();
    expect(
      find.textContaining('1 torrent still sharing stays'),
      findsOneWidget,
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Clear list'));
    await tester.pumpAndSettle();

    expect(ids(), ['b']);
    expect(file.existsSync(), isTrue);

    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(ids(), ['a', 'b']);
  });
}
