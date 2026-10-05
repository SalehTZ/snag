import 'package:flutter/material.dart';

import '../engine/models.dart';

enum SponsorBlockMode { off, mark, remove }

enum UpdateChannel { stable, nightly }

/// Every user preference, persisted as one JSON blob.
@immutable
class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.dynamicColor = true,
    this.seedColor = 0xFF6750A4,
    this.downloadDir,
    this.filenameTemplate = defaultFilenameTemplate,
    this.defaultMode = DownloadMode.video,
    this.defaultQuality = VideoQuality.best,
    this.defaultAudioFormat = AudioFormat.mp3,
    this.preferCompatible = true,
    this.embedMetadata = true,
    this.embedThumbnail = true,
    this.embedChapters = true,
    this.embedSubtitles = false,
    this.subtitleLangs = 'en.*',
    this.sponsorBlock = SponsorBlockMode.off,
    this.cookiesFile,
    this.cookiesFromBrowser,
    this.proxy,
    this.rateLimit,
    this.useAria2c = false,
    this.concurrency = 2,
    this.restrictFilenames = false,
    this.ytDlpPath,
    this.ffmpegPath,
    this.updateChannel = UpdateChannel.stable,
    this.autoPaste = true,
    this.extraArgs = '',
    this.setupDone = false,
  });

  static const defaultFilenameTemplate = '%(title).180B [%(id)s].%(ext)s';

  final ThemeMode themeMode;
  final bool dynamicColor;
  final int seedColor;

  /// Null means the platform default (Downloads/Snag).
  final String? downloadDir;
  final String filenameTemplate;
  final DownloadMode defaultMode;
  final VideoQuality defaultQuality;
  final AudioFormat defaultAudioFormat;

  /// Prefer H.264/AAC in MP4 so the file plays on anything.
  final bool preferCompatible;
  final bool embedMetadata;
  final bool embedThumbnail;
  final bool embedChapters;
  final bool embedSubtitles;
  final String subtitleLangs;
  final SponsorBlockMode sponsorBlock;

  final String? cookiesFile;
  final String? cookiesFromBrowser;
  final String? proxy;
  final String? rateLimit;
  final bool useAria2c;
  final int concurrency;
  final bool restrictFilenames;

  /// Manual binary overrides (desktop). Null = managed by Snag.
  final String? ytDlpPath;
  final String? ffmpegPath;
  final UpdateChannel updateChannel;

  final bool autoPaste;

  /// Free-form yt-dlp arguments appended to every download.
  final String extraArgs;
  final bool setupDone;

  AppSettings copyWith({
    ThemeMode? themeMode,
    bool? dynamicColor,
    int? seedColor,
    String? Function()? downloadDir,
    String? filenameTemplate,
    DownloadMode? defaultMode,
    VideoQuality? defaultQuality,
    AudioFormat? defaultAudioFormat,
    bool? preferCompatible,
    bool? embedMetadata,
    bool? embedThumbnail,
    bool? embedChapters,
    bool? embedSubtitles,
    String? subtitleLangs,
    SponsorBlockMode? sponsorBlock,
    String? Function()? cookiesFile,
    String? Function()? cookiesFromBrowser,
    String? Function()? proxy,
    String? Function()? rateLimit,
    bool? useAria2c,
    int? concurrency,
    bool? restrictFilenames,
    String? Function()? ytDlpPath,
    String? Function()? ffmpegPath,
    UpdateChannel? updateChannel,
    bool? autoPaste,
    String? extraArgs,
    bool? setupDone,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      dynamicColor: dynamicColor ?? this.dynamicColor,
      seedColor: seedColor ?? this.seedColor,
      downloadDir: downloadDir != null ? downloadDir() : this.downloadDir,
      filenameTemplate: filenameTemplate ?? this.filenameTemplate,
      defaultMode: defaultMode ?? this.defaultMode,
      defaultQuality: defaultQuality ?? this.defaultQuality,
      defaultAudioFormat: defaultAudioFormat ?? this.defaultAudioFormat,
      preferCompatible: preferCompatible ?? this.preferCompatible,
      embedMetadata: embedMetadata ?? this.embedMetadata,
      embedThumbnail: embedThumbnail ?? this.embedThumbnail,
      embedChapters: embedChapters ?? this.embedChapters,
      embedSubtitles: embedSubtitles ?? this.embedSubtitles,
      subtitleLangs: subtitleLangs ?? this.subtitleLangs,
      sponsorBlock: sponsorBlock ?? this.sponsorBlock,
      cookiesFile: cookiesFile != null ? cookiesFile() : this.cookiesFile,
      cookiesFromBrowser: cookiesFromBrowser != null
          ? cookiesFromBrowser()
          : this.cookiesFromBrowser,
      proxy: proxy != null ? proxy() : this.proxy,
      rateLimit: rateLimit != null ? rateLimit() : this.rateLimit,
      useAria2c: useAria2c ?? this.useAria2c,
      concurrency: concurrency ?? this.concurrency,
      restrictFilenames: restrictFilenames ?? this.restrictFilenames,
      ytDlpPath: ytDlpPath != null ? ytDlpPath() : this.ytDlpPath,
      ffmpegPath: ffmpegPath != null ? ffmpegPath() : this.ffmpegPath,
      updateChannel: updateChannel ?? this.updateChannel,
      autoPaste: autoPaste ?? this.autoPaste,
      extraArgs: extraArgs ?? this.extraArgs,
      setupDone: setupDone ?? this.setupDone,
    );
  }

  Map<String, Object?> toJson() => {
        'themeMode': themeMode.name,
        'dynamicColor': dynamicColor,
        'seedColor': seedColor,
        'downloadDir': downloadDir,
        'filenameTemplate': filenameTemplate,
        'defaultMode': defaultMode.name,
        'defaultQuality': defaultQuality.name,
        'defaultAudioFormat': defaultAudioFormat.name,
        'preferCompatible': preferCompatible,
        'embedMetadata': embedMetadata,
        'embedThumbnail': embedThumbnail,
        'embedChapters': embedChapters,
        'embedSubtitles': embedSubtitles,
        'subtitleLangs': subtitleLangs,
        'sponsorBlock': sponsorBlock.name,
        'cookiesFile': cookiesFile,
        'cookiesFromBrowser': cookiesFromBrowser,
        'proxy': proxy,
        'rateLimit': rateLimit,
        'useAria2c': useAria2c,
        'concurrency': concurrency,
        'restrictFilenames': restrictFilenames,
        'ytDlpPath': ytDlpPath,
        'ffmpegPath': ffmpegPath,
        'updateChannel': updateChannel.name,
        'autoPaste': autoPaste,
        'extraArgs': extraArgs,
        'setupDone': setupDone,
      };

  factory AppSettings.fromJson(Map<String, Object?> j) {
    const d = AppSettings();
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.where((v) => v.name == name).firstOrNull ?? fallback;
    return AppSettings(
      themeMode: pick(ThemeMode.values, j['themeMode'], d.themeMode),
      dynamicColor: j['dynamicColor'] as bool? ?? d.dynamicColor,
      seedColor: j['seedColor'] as int? ?? d.seedColor,
      downloadDir: j['downloadDir'] as String?,
      filenameTemplate: j['filenameTemplate'] as String? ?? d.filenameTemplate,
      defaultMode: pick(DownloadMode.values, j['defaultMode'], d.defaultMode),
      defaultQuality:
          pick(VideoQuality.values, j['defaultQuality'], d.defaultQuality),
      defaultAudioFormat: pick(
          AudioFormat.values, j['defaultAudioFormat'], d.defaultAudioFormat),
      preferCompatible: j['preferCompatible'] as bool? ?? d.preferCompatible,
      embedMetadata: j['embedMetadata'] as bool? ?? d.embedMetadata,
      embedThumbnail: j['embedThumbnail'] as bool? ?? d.embedThumbnail,
      embedChapters: j['embedChapters'] as bool? ?? d.embedChapters,
      embedSubtitles: j['embedSubtitles'] as bool? ?? d.embedSubtitles,
      subtitleLangs: j['subtitleLangs'] as String? ?? d.subtitleLangs,
      sponsorBlock:
          pick(SponsorBlockMode.values, j['sponsorBlock'], d.sponsorBlock),
      cookiesFile: j['cookiesFile'] as String?,
      cookiesFromBrowser: j['cookiesFromBrowser'] as String?,
      proxy: j['proxy'] as String?,
      rateLimit: j['rateLimit'] as String?,
      useAria2c: j['useAria2c'] as bool? ?? d.useAria2c,
      concurrency: (j['concurrency'] as int? ?? d.concurrency).clamp(1, 8),
      restrictFilenames: j['restrictFilenames'] as bool? ?? d.restrictFilenames,
      ytDlpPath: j['ytDlpPath'] as String?,
      ffmpegPath: j['ffmpegPath'] as String?,
      updateChannel:
          pick(UpdateChannel.values, j['updateChannel'], d.updateChannel),
      autoPaste: j['autoPaste'] as bool? ?? d.autoPaste,
      extraArgs: j['extraArgs'] as String? ?? d.extraArgs,
      setupDone: j['setupDone'] as bool? ?? d.setupDone,
    );
  }
}
