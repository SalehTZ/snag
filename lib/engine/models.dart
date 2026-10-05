import 'package:flutter/foundation.dart';

enum DownloadMode { video, audio }

enum VideoQuality {
  best(null, 'Best'),
  p2160(2160, '4K'),
  p1440(1440, '1440p'),
  p1080(1080, '1080p'),
  p720(720, '720p'),
  p480(480, '480p'),
  p360(360, '360p');

  const VideoQuality(this.height, this.label);
  final int? height;
  final String label;
}

enum AudioFormat {
  best(null, 'Best'),
  mp3('mp3', 'MP3'),
  m4a('m4a', 'M4A'),
  opus('opus', 'Opus'),
  flac('flac', 'FLAC');

  const AudioFormat(this.codec, this.label);
  final String? codec;
  final String label;
}

/// One entry of yt-dlp's `formats` list.
@immutable
class MediaFormat {
  const MediaFormat({
    required this.id,
    required this.ext,
    this.height,
    this.width,
    this.fps,
    this.vcodec,
    this.acodec,
    this.abr,
    this.tbr,
    this.filesize,
    this.note,
  });

  final String id;
  final String ext;
  final int? height;
  final int? width;
  final double? fps;
  final String? vcodec;
  final String? acodec;
  final double? abr;
  final double? tbr;
  final int? filesize;
  final String? note;

  bool get hasVideo => vcodec != null && vcodec != 'none';
  bool get hasAudio => acodec != null && acodec != 'none';

  /// e.g. "1080p60 · vp9 · webm" or "128k · opus · webm".
  String get label {
    final parts = <String>[];
    if (hasVideo) {
      final fpsPart = (fps ?? 0) > 30 ? fps!.round().toString() : '';
      parts.add(height != null ? '${height}p$fpsPart' : (note ?? 'video'));
      parts.add(_shortCodec(vcodec!));
    } else if (hasAudio) {
      parts.add(abr != null ? '${abr!.round()}k' : (note ?? 'audio'));
      parts.add(_shortCodec(acodec!));
    } else {
      parts.add(note ?? id);
    }
    parts.add(ext);
    return parts.join(' · ');
  }

  static String _shortCodec(String c) => c.split('.').first;

  factory MediaFormat.fromJson(Map<String, dynamic> j) => MediaFormat(
        id: '${j['format_id']}',
        ext: j['ext'] as String? ?? '?',
        height: _int(j['height']),
        width: _int(j['width']),
        fps: _double(j['fps']),
        vcodec: j['vcodec'] as String?,
        acodec: j['acodec'] as String?,
        abr: _double(j['abr']),
        tbr: _double(j['tbr']),
        filesize: _int(j['filesize']) ?? _int(j['filesize_approx']),
        note: j['format_note'] as String?,
      );
}

/// A flat entry inside a playlist.
@immutable
class PlaylistEntry {
  const PlaylistEntry({
    required this.url,
    required this.title,
    this.id,
    this.duration,
    this.uploader,
    this.thumbnail,
  });

  final String url;
  final String title;
  final String? id;
  final double? duration;
  final String? uploader;
  final String? thumbnail;

  factory PlaylistEntry.fromJson(Map<String, dynamic> j) {
    final url = (j['url'] ?? j['webpage_url'] ?? j['original_url']) as String?;
    return PlaylistEntry(
      url: url ?? '',
      id: j['id'] as String?,
      title: (j['title'] as String?)?.trim().isNotEmpty == true
          ? j['title'] as String
          : (j['id'] as String? ?? 'Untitled'),
      duration: _double(j['duration']),
      uploader: (j['uploader'] ?? j['channel']) as String?,
      thumbnail: _bestThumbnail(j),
    );
  }
}

/// Result of `yt-dlp -J --flat-playlist`: a single video or a playlist.
@immutable
class MediaInfo {
  const MediaInfo({
    required this.url,
    required this.title,
    this.id,
    this.uploader,
    this.thumbnail,
    this.duration,
    this.extractor,
    this.formats = const [],
    this.subtitleLangs = const [],
    this.isPlaylist = false,
    this.entries = const [],
  });

  final String url;
  final String title;
  final String? id;
  final String? uploader;
  final String? thumbnail;
  final double? duration;
  final String? extractor;
  final List<MediaFormat> formats;
  final List<String> subtitleLangs;
  final bool isPlaylist;
  final List<PlaylistEntry> entries;

  /// Distinct video heights available, highest first.
  List<int> get availableHeights {
    final hs = formats
        .where((f) => f.hasVideo && f.height != null)
        .map((f) => f.height!)
        .toSet()
        .toList()
      ..sort((a, b) => b.compareTo(a));
    return hs;
  }

  factory MediaInfo.fromJson(Map<String, dynamic> j, {String? requestedUrl}) {
    final type = j['_type'] as String?;
    final isPlaylist = type == 'playlist' || type == 'multi_video';
    final rawEntries = (j['entries'] as List?) ?? const [];
    final subs = <String>{
      ...((j['subtitles'] as Map?)?.keys.cast<String>() ?? const []),
    }.toList()
      ..sort();
    return MediaInfo(
      url: (j['webpage_url'] ?? j['original_url'] ?? requestedUrl ?? '')
          as String,
      title: (j['title'] as String?)?.trim().isNotEmpty == true
          ? j['title'] as String
          : (j['id'] as String? ?? 'Untitled'),
      id: j['id'] as String?,
      uploader: (j['uploader'] ?? j['channel'] ?? j['uploader_id']) as String?,
      thumbnail: _bestThumbnail(j),
      duration: _double(j['duration']),
      extractor: (j['extractor_key'] ?? j['extractor']) as String?,
      formats: ((j['formats'] as List?) ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(MediaFormat.fromJson)
          .where((f) => f.hasVideo || f.hasAudio)
          .toList()
          .reversed // yt-dlp lists worst first
          .toList(),
      subtitleLangs: subs,
      isPlaylist: isPlaylist,
      entries: rawEntries
          .whereType<Map<String, dynamic>>()
          .map(PlaylistEntry.fromJson)
          .where((e) => e.url.isNotEmpty)
          .toList(),
    );
  }
}

/// What the user asked for. Also what gets persisted for re-download.
@immutable
class DownloadSpec {
  const DownloadSpec({
    required this.url,
    this.mode = DownloadMode.video,
    this.quality = VideoQuality.best,
    this.audioFormat = AudioFormat.mp3,
    this.formatId,
    this.subtitles,
    this.templateArgs,
    this.templateName,
  });

  final String url;
  final DownloadMode mode;
  final VideoQuality quality;
  final AudioFormat audioFormat;

  /// Explicit `-f` selector from the advanced format picker.
  final String? formatId;

  /// Per-download override of the "embed subtitles" setting.
  final bool? subtitles;

  /// Raw yt-dlp arguments from a command template. When set, Snag skips its
  /// own format/postprocessing flags and only adds output + progress plumbing.
  final String? templateArgs;
  final String? templateName;

  DownloadSpec withUrl(String url) => DownloadSpec(
        url: url,
        mode: mode,
        quality: quality,
        audioFormat: audioFormat,
        formatId: formatId,
        subtitles: subtitles,
        templateArgs: templateArgs,
        templateName: templateName,
      );

  Map<String, Object?> toJson() => {
        'url': url,
        'mode': mode.name,
        'quality': quality.name,
        'audioFormat': audioFormat.name,
        'formatId': formatId,
        'subtitles': subtitles,
        'templateArgs': templateArgs,
        'templateName': templateName,
      };

  factory DownloadSpec.fromJson(Map<String, dynamic> j) => DownloadSpec(
        url: j['url'] as String,
        mode: DownloadMode.values.byNameOr(j['mode'], DownloadMode.video),
        quality: VideoQuality.values.byNameOr(j['quality'], VideoQuality.best),
        audioFormat:
            AudioFormat.values.byNameOr(j['audioFormat'], AudioFormat.mp3),
        formatId: j['formatId'] as String?,
        subtitles: j['subtitles'] as bool?,
        templateArgs: j['templateArgs'] as String?,
        templateName: j['templateName'] as String?,
      );
}

/// Display metadata known before (or learned during) a download.
@immutable
class MediaMeta {
  const MediaMeta({
    this.title,
    this.uploader,
    this.thumbnail,
    this.duration,
    this.extractor,
  });

  final String? title;
  final String? uploader;
  final String? thumbnail;
  final double? duration;
  final String? extractor;

  MediaMeta merge(MediaMeta other) => MediaMeta(
        title: title ?? other.title,
        uploader: uploader ?? other.uploader,
        thumbnail: thumbnail ?? other.thumbnail,
        duration: duration ?? other.duration,
        extractor: extractor ?? other.extractor,
      );

  factory MediaMeta.fromInfo(MediaInfo i) => MediaMeta(
        title: i.title,
        uploader: i.uploader,
        thumbnail: i.thumbnail,
        duration: i.duration,
        extractor: i.extractor,
      );

  factory MediaMeta.fromEntry(PlaylistEntry e) => MediaMeta(
        title: e.title,
        uploader: e.uploader,
        thumbnail: e.thumbnail,
        duration: e.duration,
      );

  factory MediaMeta.fromJson(Map<String, dynamic> j) => MediaMeta(
        title: j['title'] as String?,
        uploader: (j['uploader'] ?? j['channel']) as String?,
        thumbnail: j['thumbnail'] as String?,
        duration: _double(j['duration']),
        extractor: (j['extractor_key'] ?? j['extractor']) as String?,
      );

  Map<String, Object?> toJson() => {
        'title': title,
        'uploader': uploader,
        'thumbnail': thumbnail,
        'duration': duration,
        'extractor': extractor,
      };
}

/// One parsed `download:` progress line.
@immutable
class ProgressUpdate {
  const ProgressUpdate({
    required this.status,
    this.downloaded,
    this.total,
    this.speed,
    this.eta,
    this.fragmentIndex,
    this.fragmentCount,
  });

  final String status;
  final int? downloaded;
  final int? total;
  final double? speed;
  final double? eta;
  final int? fragmentIndex;
  final int? fragmentCount;

  double? get fraction {
    if (total != null && total! > 0 && downloaded != null) {
      return (downloaded! / total!).clamp(0.0, 1.0);
    }
    if (fragmentCount != null && fragmentCount! > 0 && fragmentIndex != null) {
      return (fragmentIndex! / fragmentCount!).clamp(0.0, 1.0);
    }
    return null;
  }

  factory ProgressUpdate.fromJson(Map<String, dynamic> j) => ProgressUpdate(
        status: j['status'] as String? ?? 'downloading',
        downloaded: _int(j['downloaded_bytes']),
        total: _int(j['total_bytes']) ?? _int(j['total_bytes_estimate']),
        speed: _double(j['speed']),
        eta: _double(j['eta']),
        fragmentIndex: _int(j['fragment_index']),
        fragmentCount: _int(j['fragment_count']),
      );
}

String? _bestThumbnail(Map<String, dynamic> j) {
  final direct = j['thumbnail'];
  if (direct is String && direct.isNotEmpty) return direct;
  final list = j['thumbnails'];
  if (list is List && list.isNotEmpty) {
    final last = list.last;
    if (last is Map && last['url'] is String) return last['url'] as String;
  }
  return null;
}

int? _int(Object? v) => v is num ? v.toInt() : null;
double? _double(Object? v) => v is num ? v.toDouble() : null;

extension EnumByNameOr<T extends Enum> on List<T> {
  T byNameOr(Object? name, T fallback) =>
      where((v) => v.name == name).firstOrNull ?? fallback;
}
