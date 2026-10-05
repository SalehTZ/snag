import 'package:flutter_test/flutter_test.dart';
import 'package:snag/engine/output_parser.dart';

void main() {
  // Captured verbatim from yt-dlp 2026.03.17.
  const progressLine =
      'SNAG_P{"status": "downloading", "downloaded_bytes": 3072, '
      '"total_bytes": 991017, "tmpfilename": "./a.mp4.part", '
      '"filename": "./a.mp4", "eta": 4, "speed": 250000.5, "elapsed": 0.68, '
      '"ctx_id": null, "_percent": 0.3}';
  const infoLine =
      'SNAG_I{"id": "Big_Buck_Bunny", "title": "Big Buck Bunny", '
      '"webpage_url": "https://x/y.mp4", "extractor_key": "Generic"}';

  test('progress line', () {
    final e = EngineEvent.parse(progressLine) as ProgressEvent;
    expect(e.progress.downloaded, 3072);
    expect(e.progress.total, 991017);
    expect(e.progress.speed, closeTo(250000.5, 0.01));
    expect(e.progress.eta, 4);
    expect(e.progress.fraction, closeTo(3072 / 991017, 1e-9));
  });

  test('fragment-only progress (HLS) still has a fraction', () {
    final e = EngineEvent.parse(
            'SNAG_P{"status":"downloading","fragment_index":3,"fragment_count":12}')
        as ProgressEvent;
    expect(e.progress.fraction, 0.25);
  });

  test('estimate is used when total is unknown', () {
    final e = EngineEvent.parse(
        'SNAG_P{"status":"downloading","downloaded_bytes":50,'
        '"total_bytes":null,"total_bytes_estimate":200}') as ProgressEvent;
    expect(e.progress.fraction, 0.25);
  });

  test('postprocess line is not mistaken for progress', () {
    final e = EngineEvent.parse('SNAG_PPMerger|started');
    expect(e, isA<PostprocessEvent>());
    e as PostprocessEvent;
    expect(e.name, 'Merger');
    expect(e.status, 'started');
    expect(e.label, 'Merging video and audio');
  });

  test('info and file lines', () {
    final meta = EngineEvent.parse(infoLine) as MetaEvent;
    expect(meta.meta.title, 'Big Buck Bunny');
    expect(meta.meta.extractor, 'Generic');
    final file =
        EngineEvent.parse('SNAG_F/home/me/Downloads/Snag/a b [x].mp4') as FileEvent;
    expect(file.path, '/home/me/Downloads/Snag/a b [x].mp4');
  });

  test('errors, warnings and noise', () {
    final err = EngineEvent.parse('ERROR: [youtube] abc: Video unavailable');
    expect((err as LogEvent).level, LogLevel.error);
    expect(err.message, '[youtube] abc: Video unavailable');
    final warn = EngineEvent.parse('WARNING: something');
    expect((warn as LogEvent).level, LogLevel.warning);
    expect(EngineEvent.parse('[download] whatever'), isA<LogEvent>());
  });

  test('broken JSON never throws', () {
    expect(EngineEvent.parse('SNAG_P{not json'), isA<LogEvent>());
    expect(EngineEvent.parse(''), isA<LogEvent>());
  });

  test('friendly errors', () {
    expect(
      friendlyError("[youtube] x: Sign in to confirm you’re not a bot. Use --cookies"),
      contains('cookies'),
    );
    expect(friendlyError('Unsupported URL: https://a.b'), contains('not supported'));
    expect(friendlyError('something odd'), 'something odd');
  });
}
