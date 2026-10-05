import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:snag/core/format.dart';
import 'package:snag/data/records.dart';
import 'package:snag/data/settings.dart';
import 'package:snag/engine/models.dart';

void main() {
  group('MediaInfo', () {
    test('single video with formats and subtitles', () {
      final info = MediaInfo.fromJson({
        'id': 'abc',
        'title': 'A video',
        'uploader': 'Someone',
        'webpage_url': 'https://www.youtube.com/watch?v=abc',
        'extractor_key': 'Youtube',
        'duration': 212,
        'thumbnails': [
          {'url': 'https://i/small.jpg'},
          {'url': 'https://i/big.jpg'},
        ],
        'subtitles': {'en': [], 'de': [], 'live_chat': []},
        'formats': [
          {'format_id': 'sb0', 'ext': 'mhtml', 'vcodec': 'none', 'acodec': 'none'},
          {'format_id': '140', 'ext': 'm4a', 'vcodec': 'none', 'acodec': 'mp4a.40.2', 'abr': 129.5},
          {'format_id': '137', 'ext': 'mp4', 'vcodec': 'avc1.640028', 'acodec': 'none', 'height': 1080, 'fps': 30},
          {'format_id': '313', 'ext': 'webm', 'vcodec': 'vp9', 'acodec': 'none', 'height': 2160, 'fps': 60, 'filesize': 123456789},
        ],
      });
      expect(info.isPlaylist, isFalse);
      expect(info.thumbnail, 'https://i/big.jpg');
      // Storyboards dropped, best first.
      expect(info.formats.map((f) => f.id), ['313', '137', '140']);
      expect(info.availableHeights, [2160, 1080]);
      expect(info.formats.first.label, '2160p60 · vp9 · webm');
      expect(info.formats.last.label, '130k · mp4a · m4a');
      expect(info.subtitleLangs, ['de', 'en', 'live_chat']);
    });

    test('flat playlist', () {
      final info = MediaInfo.fromJson({
        '_type': 'playlist',
        'id': 'PL1',
        'title': 'Mix',
        'entries': [
          {'url': 'https://youtu.be/1', 'title': 'One', 'duration': 60},
          {'url': 'https://youtu.be/2', 'title': '', 'id': 'two'},
          {'title': 'no url, skipped'},
        ],
      }, requestedUrl: 'https://youtube.com/playlist?list=PL1');
      expect(info.isPlaylist, isTrue);
      expect(info.url, 'https://youtube.com/playlist?list=PL1');
      expect(info.entries, hasLength(2));
      expect(info.entries[1].title, 'two');
    });
  });

  test('DownloadSpec round-trips', () {
    const spec = DownloadSpec(
      url: 'u',
      mode: DownloadMode.audio,
      audioFormat: AudioFormat.flac,
      formatId: '251',
      subtitles: false,
      templateName: 'T',
      templateArgs: '-x',
    );
    final back = DownloadSpec.fromJson(
        jsonDecode(jsonEncode(spec.toJson())) as Map<String, dynamic>);
    expect(back.toJson(), spec.toJson());
  });

  test('HistoryItem round-trips', () {
    final item = HistoryItem(
      id: '1',
      spec: const DownloadSpec(url: 'u'),
      meta: const MediaMeta(title: 't', duration: 3.5),
      finishedAt: DateTime.utc(2026, 1, 2),
      filePath: '/a.mp4',
      fileSize: 10,
    );
    final back = HistoryItem.fromJson(
        jsonDecode(jsonEncode(item.toJson())) as Map<String, dynamic>);
    expect(back.toJson(), item.toJson());
  });

  test('AppSettings round-trips and tolerates junk', () {
    const s = AppSettings(
      themeMode: ThemeMode.dark,
      proxy: 'p',
      concurrency: 4,
      sponsorBlock: SponsorBlockMode.remove,
    );
    final back = AppSettings.fromJson(
        jsonDecode(jsonEncode(s.toJson())) as Map<String, Object?>);
    expect(back.toJson(), s.toJson());

    final junk = AppSettings.fromJson({'themeMode': 'purple', 'concurrency': 99});
    expect(junk.themeMode, ThemeMode.system);
    expect(junk.concurrency, 8);
  });

  group('format helpers', () {
    test('bytes, durations, eta', () {
      expect(formatBytes(0), '0 B');
      expect(formatBytes(1536), '1.5 KB');
      expect(formatBytes(null), '-');
      expect(formatDuration(75), '1:15');
      expect(formatDuration(3725), '1:02:05');
      expect(formatEta(42), '42s');
      expect(formatEta(200), '3m 20s');
    });

    test('plurals', () {
      expect(plural(0, 'item'), '0 items');
      expect(plural(1, 'item'), '1 item');
      expect(plural(2, 'item'), '2 items');
    });

    test('relative time across a month boundary', () {
      final now = DateTime(2026, 3, 1, 10);
      expect(formatRelative(DateTime(2026, 2, 28, 22), now: now), 'yesterday');
      expect(formatRelative(DateTime(2026, 3, 1, 7), now: now), '3 hours ago');
      expect(formatRelative(DateTime(2025, 2, 3), now: now), '3 Feb 2025');
    });

    test('extractUrl pulls links out of shared text', () {
      expect(extractUrl('Watch this! https://youtu.be/abc?t=3 wow'),
          'https://youtu.be/abc?t=3');
      expect(extractUrl('no link here'), isNull);
    });
  });
}
