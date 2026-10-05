import 'dart:convert';

import 'models.dart';

/// Markers Snag asks yt-dlp to print, so output is machine-readable on every
/// platform (desktop process pipes and the Android bridge alike).
abstract final class Marker {
  static const progress = 'SNAG_P';
  static const postprocess = 'SNAG_PP';
  static const info = 'SNAG_I';
  static const file = 'SNAG_F';
}

sealed class EngineEvent {
  const EngineEvent();

  /// Parses one line of yt-dlp output. Never throws.
  static EngineEvent parse(String rawLine) {
    final line = rawLine.trimRight();
    // Order matters: SNAG_PP starts with SNAG_P.
    if (line.startsWith(Marker.postprocess)) {
      final body = line.substring(Marker.postprocess.length);
      final parts = body.split('|');
      return PostprocessEvent(parts.first, parts.length > 1 ? parts[1] : '');
    }
    if (line.startsWith(Marker.progress)) {
      final json = _json(line.substring(Marker.progress.length));
      if (json != null) return ProgressEvent(ProgressUpdate.fromJson(json));
    }
    if (line.startsWith(Marker.info)) {
      final json = _json(line.substring(Marker.info.length));
      if (json != null) return MetaEvent(MediaMeta.fromJson(json));
    }
    if (line.startsWith(Marker.file)) {
      return FileEvent(line.substring(Marker.file.length));
    }
    if (line.startsWith('ERROR:')) {
      return LogEvent(line.substring(6).trim(), level: LogLevel.error);
    }
    if (line.startsWith('WARNING:')) {
      return LogEvent(line.substring(8).trim(), level: LogLevel.warning);
    }
    return LogEvent(line);
  }

  static Map<String, dynamic>? _json(String s) {
    try {
      final v = jsonDecode(s);
      return v is Map<String, dynamic> ? v : null;
    } on FormatException {
      return null;
    }
  }
}

class ProgressEvent extends EngineEvent {
  const ProgressEvent(this.progress);
  final ProgressUpdate progress;
}

class PostprocessEvent extends EngineEvent {
  const PostprocessEvent(this.name, this.status);
  final String name;
  final String status;

  /// Friendly label for the step yt-dlp is running.
  String get label => switch (name) {
        'Merger' => 'Merging video and audio',
        'ExtractAudio' || 'FFmpegExtractAudio' => 'Converting audio',
        'EmbedThumbnail' => 'Embedding thumbnail',
        'FFmpegMetadata' || 'Metadata' => 'Writing metadata',
        'FFmpegEmbedSubtitle' || 'EmbedSubtitle' => 'Embedding subtitles',
        'SponsorBlock' || 'ModifyChapters' => 'Cutting sponsor segments',
        'MoveFiles' => 'Finishing up',
        _ => 'Processing',
      };
}

class MetaEvent extends EngineEvent {
  const MetaEvent(this.meta);
  final MediaMeta meta;
}

class FileEvent extends EngineEvent {
  const FileEvent(this.path);
  final String path;
}

enum LogLevel { info, warning, error }

class LogEvent extends EngineEvent {
  const LogEvent(this.message, {this.level = LogLevel.info});
  final String message;
  final LogLevel level;
}

/// Turns raw yt-dlp error text into something a human can act on.
String friendlyError(String raw) {
  final s = raw.toLowerCase();
  if (s.contains('confirm you') && s.contains('not a bot')) {
    return 'The site wants proof you are human. Add your browser cookies in '
        'Settings > Network, then try again.';
  }
  if (s.contains('unsupported url')) {
    return 'This link is not supported. Check that it points to a video or '
        'playlist page.';
  }
  if (s.contains('private video') || s.contains('members-only')) {
    return 'This video is private or members-only. Cookies from a signed-in '
        'browser may help.';
  }
  if (s.contains('sign in') || s.contains('login required')) {
    return 'This content needs you to be signed in. Add cookies in '
        'Settings > Network.';
  }
  if (s.contains('http error 429') || s.contains('too many requests')) {
    return 'The site is rate-limiting you. Wait a bit, or use a proxy.';
  }
  if (s.contains('unable to download webpage') ||
      s.contains('failed to resolve') ||
      s.contains('network is unreachable') ||
      s.contains('timed out')) {
    return 'Could not reach the site. Check your connection or proxy.';
  }
  if (s.contains('ffmpeg') && s.contains('not found')) {
    return 'ffmpeg is missing, so audio conversion and merging cannot run. '
        'Install it from Settings > Components.';
  }
  if (s.contains('requested format is not available')) {
    return 'That quality is not available for this video. Try "Best".';
  }
  return raw;
}
