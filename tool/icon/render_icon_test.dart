// Renders the app icon PNGs from code, so the brand mark stays editable:
//
//   flutter test tool/icon --update-goldens
//   dart run flutter_launcher_icons
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snag/widgets/shapes.dart';

const brand = Color(0xFF6B2CF5);
const brandDeep = Color(0xFF4A12C9);

Future<void> loadIcons() async {
  final sdk = Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable).parent.parent.parent.parent.parent.path;
  final loader = FontLoader('MaterialIcons')
    ..addFont(Future.value(ByteData.sublistView(File(
            '$sdk/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf')
        .readAsBytesSync())));
  await loader.load();
}

/// The mark: a vivid scalloped cookie with a heavy down arrow.
class Mark extends StatelessWidget {
  const Mark({super.key, this.background = false, this.inset = 0});

  /// Full-bleed square background (Android legacy/iOS-style) vs transparent.
  final bool background;

  /// Shrinks the cookie for adaptive-icon safe zones.
  final double inset;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: background ? const Color(0xFFF3EDFF) : Colors.transparent,
      child: Padding(
        padding: EdgeInsets.all(inset),
        child: LayoutBuilder(builder: (context, c) {
          final size = c.biggest.shortestSide;
          return Stack(alignment: Alignment.center, children: [
            DecoratedBox(
              decoration: const ShapeDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [brand, brandDeep],
                ),
                shape: CookieBorder(lobes: 9, depth: 0.11),
              ),
              child: SizedBox.square(dimension: size),
            ),
            CustomPaint(size: Size.square(size), painter: _Arrow()),
          ]);
        }),
      ),
    );
  }
}

/// A heavy, rounded down arrow resting on a short "landing" bar.
class _Arrow extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width;
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = s * 0.095
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final cx = s / 2;
    final top = s * 0.27, tip = s * 0.62, wing = s * 0.16;
    canvas.drawLine(Offset(cx, top), Offset(cx, tip), paint);
    canvas.drawPath(
      Path()
        ..moveTo(cx - wing, tip - wing)
        ..lineTo(cx, tip)
        ..lineTo(cx + wing, tip - wing),
      paint,
    );
    canvas.drawLine(
        Offset(cx - s * 0.17, s * 0.75), Offset(cx + s * 0.17, s * 0.75), paint);
  }

  @override
  bool shouldRepaint(_Arrow oldDelegate) => false;
}

Future<void> render(WidgetTester tester, String name, Widget child) async {
  tester.view.physicalSize = const Size(1024, 1024);
  tester.view.devicePixelRatio = 1;
  await tester.pumpWidget(Directionality(
    textDirection: TextDirection.ltr,
    child: RepaintBoundary(child: child),
  ));
  await expectLater(find.byType(RepaintBoundary).first,
      matchesGoldenFile('../../assets/icon/$name.png'));
}

void main() {
  setUpAll(loadIcons);

  testWidgets('icon', (t) => render(t, 'icon', const Mark(inset: 40)));
  testWidgets('android foreground',
      (t) => render(t, 'foreground', const Mark(inset: 250)));
}
