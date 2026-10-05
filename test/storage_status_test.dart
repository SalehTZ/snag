import 'package:flutter_test/flutter_test.dart';
import 'package:snag/core/platform_actions.dart';

StorageStatus android({
  int sdk = 33,
  bool legacyGranted = true,
  bool allFiles = false,
}) =>
    StorageStatus(
      sdk: sdk,
      needsLegacyPermission: sdk <= 29,
      legacyGranted: legacyGranted,
      allFilesAccess: allFiles,
      externalRoot: '/storage/emulated/0',
    );

void main() {
  group('Android 11+', () {
    test('Download and Documents need no permission', () {
      final s = android();
      expect(s.canWriteTo('/storage/emulated/0/Download/Snag'), isTrue);
      expect(s.canWriteTo('/storage/emulated/0/Download'), isTrue);
      expect(s.canWriteTo('/storage/emulated/0/Documents/Videos'), isTrue);
    });

    test('other folders need All files access', () {
      final s = android();
      expect(s.canWriteTo('/storage/emulated/0/Movies'), isFalse);
      expect(s.canWriteTo('/storage/emulated/0/MyStuff'), isFalse);
      // Prefix lookalikes are not the real folder.
      expect(s.canWriteTo('/storage/emulated/0/Downloads2'), isFalse);
      expect(android(allFiles: true).canWriteTo('/storage/emulated/0/MyStuff'),
          isTrue);
    });
  });

  test('Android 10 and older need the legacy permission everywhere', () {
    expect(android(sdk: 29, legacyGranted: false)
        .canWriteTo('/storage/emulated/0/Download/Snag'), isFalse);
    expect(android(sdk: 28, legacyGranted: true)
        .canWriteTo('/storage/emulated/0/Anything'), isTrue);
  });

  test('desktop can always write', () {
    expect(const StorageStatus.desktop().canWriteTo('/home/me/x'), isTrue);
  });
}
