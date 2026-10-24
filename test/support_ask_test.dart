import 'package:flutter_test/flutter_test.dart';
import 'package:snag/data/settings.dart';
import 'package:snag/features/settings/support_card.dart';

void main() {
  test('Home asks for support at a few milestones, once each', () {
    bool ask(int downloads, int askedAt) =>
        shouldAskForSupport(downloads: downloads, askedAt: askedAt);

    expect(ask(4, 0), isFalse); // too early to ask anyone
    expect(ask(5, 0), isTrue);
    expect(ask(6, 5), isFalse); // closed at 5: quiet until 50
    expect(ask(49, 7), isFalse);
    expect(ask(50, 7), isTrue);
    expect(ask(300, 0), isTrue); // updated from an old version: one ask
    expect(ask(300, 300), isFalse); // and never again
  });

  test('closing the card is remembered', () {
    const s = AppSettings(supportAskedAt: 12);
    expect(AppSettings.fromJson(s.toJson()).supportAskedAt, 12);
    expect(AppSettings.fromJson(const {}).supportAskedAt, 0);
  });
}
