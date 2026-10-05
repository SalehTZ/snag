import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:shamsi_date/shamsi_date.dart';

import '../engine/binary_manager.dart';
import '../engine/models.dart';
import '../engine/ytdlp_engine.dart';
import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

extension L10nContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
  Fmt get fmt => Fmt(AppLocalizations.of(this));
}

final _firstStrong = RegExp(r'[A-Za-z\u00C0-\u024F\u0370-\u03FF\u0400-\u04FF]|'
    r'[\u0590-\u08FF\uFB1D-\uFDFF\uFE70-\uFEFF]');

/// Direction of user content (video titles, channel names) from its first
/// strong character, so an English title stays LTR in a Persian UI and a
/// Persian title stays RTL in an English one.
TextDirection? contentDirection(String text) {
  final m = _firstStrong.firstMatch(text);
  if (m == null) return null;
  final c = m.group(0)!.codeUnitAt(0);
  return c >= 0x0590 ? TextDirection.rtl : TextDirection.ltr;
}

/// Scripts that join letters: never apply negative letter-spacing to them.
bool isCursiveScript(Locale locale) =>
    const {'fa', 'ar', 'ur', 'ps', 'ckb', 'ug'}.contains(locale.languageCode);

/// Text helpers that turn engine types into words in the current language.
extension AppStrings on AppLocalizations {
  String engineError(Object error) {
    if (error is! EngineException) return errorUnknown;
    return switch (error.kind) {
      EngineErrorKind.botCheck => errorBotCheck,
      EngineErrorKind.unsupportedUrl => errorUnsupportedUrl,
      EngineErrorKind.privateVideo => errorPrivate,
      EngineErrorKind.signInRequired => errorSignIn,
      EngineErrorKind.rateLimited => errorRateLimited,
      EngineErrorKind.network => errorNetwork,
      EngineErrorKind.ffmpegMissing => errorFfmpegMissing,
      EngineErrorKind.formatUnavailable => errorFormatUnavailable,
      EngineErrorKind.notInstalled => errorNotInstalled,
      EngineErrorKind.noMedia => errorNoMedia,
      EngineErrorKind.unexpectedOutput => errorUnexpectedOutput,
      EngineErrorKind.folderNotWritable => errorFolderNotWritable,
      EngineErrorKind.engineStart => errorEngineStart,
      EngineErrorKind.invalidLink => homeInvalidLink,
      // yt-dlp's own words beat a vague "something went wrong".
      EngineErrorKind.unknown => error.raw ?? errorUnknown,
    };
  }

  /// Raw text for an error's "details" disclosure.
  String? errorDetails(Object error) => error is EngineException
      ? (error.details ?? error.raw)
      : error.toString();

  /// Human label for the yt-dlp post-processor that is running.
  String stage(String? postprocessor) => switch (postprocessor) {
        'Merger' => stageMerging,
        'ExtractAudio' || 'FFmpegExtractAudio' => stageConvertingAudio,
        'EmbedThumbnail' => stageThumbnail,
        'FFmpegMetadata' || 'Metadata' => stageMetadata,
        'FFmpegEmbedSubtitle' || 'EmbedSubtitle' => stageSubtitles,
        'SponsorBlock' || 'ModifyChapters' => stageSponsorBlock,
        'MoveFiles' => stageFinishing,
        _ => stageProcessing,
      };

  String quality(VideoQuality q) =>
      q == VideoQuality.best ? qualityBest : q.label;

  String audio(AudioFormat a) => a == AudioFormat.best ? audioOriginal : a.label;

  /// Short description of a download, for queue and library rows.
  String summary(DownloadSpec spec) {
    if (spec.templateName != null) return spec.templateName!;
    if (spec.formatId != null) return summaryFormat(spec.formatId!);
    return spec.mode == DownloadMode.audio
        ? summaryAudio(audio(spec.audioFormat))
        : summaryVideo(quality(spec.quality));
  }

  String purpose(Component c) => switch (c) {
        Component.ytDlp => purposeYtDlp,
        Component.ffmpeg => purposeFfmpeg,
        Component.deno => purposeDeno,
      };

  String installStage(InstallStage s) => switch (s) {
        InstallStage.starting => installStarting,
        InstallStage.downloading => installDownloading,
        InstallStage.unpacking => installUnpacking,
        InstallStage.updating => installUpdating,
      };
}

/// Locale-aware formatting: native digits and separators (via intl),
/// translated units, and the Solar Hijri calendar for Persian.
class Fmt {
  Fmt(this.l) : _locale = l.localeName;

  final AppLocalizations l;
  final String _locale;

  bool get _jalali => _locale.startsWith('fa');

  String number(num value, {int decimals = 0}) {
    final f = NumberFormat.decimalPattern(_locale)
      ..minimumFractionDigits = decimals
      ..maximumFractionDigits = decimals;
    return f.format(value);
  }

  /// Digits only, no grouping: years, clock parts.
  String digits(int value, {int width = 1}) =>
      NumberFormat('0' * width, _locale).format(value);

  String percent(double fraction) =>
      NumberFormat.percentPattern(_locale).format(fraction);

  String bytes(num? bytes) {
    if (bytes == null || bytes < 0) return '-';
    var value = bytes.toDouble();
    var unit = 0;
    while (value >= 1024 && unit < 4) {
      value /= 1024;
      unit++;
    }
    final n = number(value, decimals: unit == 0 ? 0 : 1);
    return switch (unit) {
      0 => l.unitBytes(n),
      1 => l.unitKB(n),
      2 => l.unitMB(n),
      3 => l.unitGB(n),
      _ => l.unitTB(n),
    };
  }

  String speed(num? bytesPerSecond) {
    if (bytesPerSecond == null || bytesPerSecond <= 0) return '-';
    return l.unitPerSecond(bytes(bytesPerSecond));
  }

  /// 75 -> "1:15", 3725 -> "1:02:05" (with native digits).
  String duration(num? seconds) {
    if (seconds == null || seconds < 0) return '-';
    final total = seconds.round();
    final h = total ~/ 3600, m = (total % 3600) ~/ 60, s = total % 60;
    if (h > 0) return '${digits(h)}:${digits(m, width: 2)}:${digits(s, width: 2)}';
    return '${digits(m)}:${digits(s, width: 2)}';
  }

  String eta(num? seconds) {
    if (seconds == null || seconds < 0) return '-';
    final t = seconds.round();
    if (t < 60) return l.etaSeconds(digits(t));
    if (t < 3600) return l.etaMinutes(digits(t ~/ 60), digits(t % 60));
    return l.etaHours(digits(t ~/ 3600), digits((t % 3600) ~/ 60));
  }

  /// "just now", "5 min ago", "yesterday", then a short date.
  String relative(DateTime time, {DateTime? now}) {
    final n = now ?? DateTime.now();
    final diff = n.difference(time);
    if (diff.inSeconds < 45) return l.timeJustNow;
    if (diff.inMinutes < 60) return l.timeMinutesAgo(diff.inMinutes);
    final days = DateTime(n.year, n.month, n.day)
        .difference(DateTime(time.year, time.month, time.day))
        .inDays;
    if (days == 0) return l.timeHoursAgo(diff.inHours);
    if (days == 1) return l.timeYesterday;
    return date(time, now: n);
  }

  String date(DateTime time, {DateTime? now}) {
    final n = now ?? DateTime.now();
    if (_jalali) {
      final j = Jalali.fromDateTime(time);
      final base = '${digits(j.day)} ${j.formatter.mN}';
      return j.year == Jalali.fromDateTime(n).year
          ? base
          : '$base ${digits(j.year)}';
    }
    return time.year == n.year
        ? DateFormat.MMMd(_locale).format(time)
        : DateFormat.yMMMd(_locale).format(time);
  }
}
