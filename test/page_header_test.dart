import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snag/l10n/l10n.dart';
import 'package:snag/widgets/common.dart';

Widget _app(Widget home) => MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: home,
    );

void main() {
  testWidgets('opening a sheet does not add a back button to the page',
      (tester) async {
    // Like the queue screen: the page rebuilds (e.g. a provider changes)
    // while a details sheet is open on top of it.
    final tick = ValueNotifier(0);
    await tester.pumpWidget(_app(ValueListenableBuilder<int>(
      valueListenable: tick,
      builder: (context, value, _) => Scaffold(
        appBar: PageHeader(title: 'Queue $value'),
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => const SizedBox(height: 200),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    )));
    expect(find.byType(BackButton), findsNothing);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    tick.value++;
    await tester.pump();
    expect(find.text('Queue 1'), findsOneWidget);
    expect(find.byType(BackButton), findsNothing);
  });

  testWidgets('a pushed page still gets its back button', (tester) async {
    final nav = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: nav,
      home: const Scaffold(appBar: PageHeader(title: 'Settings')),
    ));
    nav.currentState!.push(MaterialPageRoute<void>(
      builder: (_) => const Scaffold(appBar: PageHeader(title: 'Templates')),
    ));
    await tester.pumpAndSettle();
    expect(find.byType(BackButton), findsOneWidget);
  });
}
