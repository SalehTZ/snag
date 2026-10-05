import 'package:flutter/foundation.dart';

import '../engine/models.dart';

/// A finished download, shown in the Library.
@immutable
class HistoryItem {
  const HistoryItem({
    required this.id,
    required this.spec,
    required this.meta,
    required this.finishedAt,
    this.filePath,
    this.fileSize,
  });

  final String id;
  final DownloadSpec spec;
  final MediaMeta meta;
  final DateTime finishedAt;
  final String? filePath;
  final int? fileSize;

  String get title => meta.title ?? spec.url;

  Map<String, Object?> toJson() => {
        'id': id,
        'spec': spec.toJson(),
        'meta': meta.toJson(),
        'finishedAt': finishedAt.toIso8601String(),
        'filePath': filePath,
        'fileSize': fileSize,
      };

  factory HistoryItem.fromJson(Map<String, dynamic> j) => HistoryItem(
        id: j['id'] as String,
        spec: DownloadSpec.fromJson(j['spec'] as Map<String, dynamic>),
        meta: MediaMeta.fromJson(j['meta'] as Map<String, dynamic>),
        finishedAt: DateTime.parse(j['finishedAt'] as String),
        filePath: j['filePath'] as String?,
        fileSize: j['fileSize'] as int?,
      );
}

/// A named set of raw yt-dlp arguments.
@immutable
class CommandTemplate {
  const CommandTemplate({
    required this.id,
    required this.name,
    required this.args,
  });

  final String id;
  final String name;
  final String args;

  CommandTemplate copyWith({String? name, String? args}) =>
      CommandTemplate(id: id, name: name ?? this.name, args: args ?? this.args);

  Map<String, Object?> toJson() => {'id': id, 'name': name, 'args': args};

  factory CommandTemplate.fromJson(Map<String, dynamic> j) => CommandTemplate(
        id: j['id'] as String,
        name: j['name'] as String,
        args: j['args'] as String,
      );

  static const defaults = [
    CommandTemplate(
      id: 'builtin-mkv-subs',
      name: 'Best quality MKV + all subtitles',
      args: '-f "bv*+ba/b" --merge-output-format mkv '
          '--write-subs --sub-langs all --embed-subs --embed-chapters',
    ),
    CommandTemplate(
      id: 'builtin-original-audio',
      name: 'Original audio, no conversion',
      args: '-f ba/b -x --embed-metadata --embed-thumbnail',
    ),
    CommandTemplate(
      id: 'builtin-thumbnail',
      name: 'Thumbnail only',
      args: '--skip-download --write-thumbnail --convert-thumbnails png',
    ),
  ];
}
