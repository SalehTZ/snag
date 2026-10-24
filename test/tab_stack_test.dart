import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snag/l10n/l10n.dart';
import 'package:snag/shell.dart';
import 'package:snag/widgets/common.dart';

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  testWidgets('a typed link survives switching tabs', (tester) async {
    final tab = ValueNotifier(0);
    await tester.pumpWidget(_app(ValueListenableBuilder<int>(
      valueListenable: tab,
      builder: (context, index, _) => Scaffold(
        body: TabStack(index: index, children: const [
          TextField(),
          Text('queue'),
        ]),
      ),
    )));

    await tester.enterText(find.byType(TextField), 'https://example.com/v');
    tab.value = 1;
    await tester.pumpAndSettle();
    expect(find.text('queue'), findsOneWidget);

    tab.value = 0;
    await tester.pumpAndSettle();
    expect(find.text('https://example.com/v'), findsOneWidget);
  });

  testWidgets('pages are built the first time they are shown',
      (tester) async {
    final tab = ValueNotifier(0);
    await tester.pumpWidget(_app(ValueListenableBuilder<int>(
      valueListenable: tab,
      builder: (context, index, _) => TabStack(
        index: index,
        children: const [Text('home'), Text('library')],
      ),
    )));
    expect(find.text('library', skipOffstage: false), findsNothing);

    tab.value = 1;
    await tester.pumpAndSettle();
    expect(find.text('library'), findsOneWidget);
  });

  testWidgets('a snackbar with an action goes away on its own',
      (tester) async {
    await tester.pumpWidget(_app(Scaffold(
      body: Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => showSnack(context, 'Added to queue',
              actionLabel: 'View', onAction: () {}),
          child: const Text('go'),
        ),
      ),
    )));

    await tester.tap(find.text('go'));
    await tester.pumpAndSettle();
    expect(find.text('Added to queue'), findsOneWidget);

    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
    expect(find.text('Added to queue'), findsNothing);
  });
}
