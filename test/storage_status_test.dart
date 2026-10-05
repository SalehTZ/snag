import 'package:flutter_test/flutter_test.dart';
import 'package:snag/core/platform_actions.dart';

StorageStatus android({int sdk = 33, bool legacyGranted = true}) =>
    StorageStatus(
      sdk: sdk,
      needsLegacyPermission: sdk <= 29,
      legacyGranted: legacyGranted,
      externalRoot: '/storage/emulated/0',
    );

void main() {
  group('Android 11+', () {
    test('Download and Documents (and folders inside) are allowed', () {
      final s = android();
      expect(s.isAllowedFolder('/storage/emulated/0/Download/Snag'), isTrue);
      expect(s.isAllowedFolder('/storage/emulated/0/Download'), isTrue);
      expect(s.isAllowedFolder('/storage/emulated/0/Documents/Videos'), isTrue);
    });

    test('anything else is not', () {
      final s = android();
      expect(s.isAllowedFolder('/storage/emulated/0/Movies'), isFalse);
      expect(s.isAllowedFolder('/storage/emulated/0/MyStuff'), isFalse);
      // Prefix lookalikes are not the real folder.
      expect(s.isAllowedFolder('/storage/emulated/0/Downloads2'), isFalse);
    });
  });

  test('Android 10 and older: any folder, gated by the legacy permission', () {
    expect(android(sdk: 29).isAllowedFolder('/storage/emulated/0/Anything'),
        isTrue);
  });

  test('desktop allows any folder', () {
    expect(const StorageStatus.desktop().isAllowedFolder('/home/me/x'), isTrue);
  });
}
