/// Small, dependency-free formatters for sizes, speeds and durations.
library;

String formatBytes(num? bytes, {int decimals = 1}) {
  if (bytes == null || bytes < 0) return '-';
  const units = ['B', 'KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final digits = unit == 0 ? 0 : decimals;
  return '${value.toStringAsFixed(digits)} ${units[unit]}';
}

String formatSpeed(num? bytesPerSecond) {
  if (bytesPerSecond == null || bytesPerSecond <= 0) return '-';
  return '${formatBytes(bytesPerSecond)}/s';
}

/// 75 -> "1:15", 3725 -> "1:02:05".
String formatDuration(num? seconds) {
  if (seconds == null || seconds < 0) return '-';
  final total = seconds.round();
  final h = total ~/ 3600;
  final m = (total % 3600) ~/ 60;
  final s = total % 60;
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:${m.toString().padLeft(2, '0')}:$ss';
  return '$m:$ss';
}

/// Short human ETA: "12s", "3m 20s", "1h 4m".
String formatEta(num? seconds) {
  if (seconds == null || seconds < 0) return '-';
  final total = seconds.round();
  if (total < 60) return '${total}s';
  if (total < 3600) return '${total ~/ 60}m ${total % 60}s';
  return '${total ~/ 3600}h ${(total % 3600) ~/ 60}m';
}

String plural(int count, String singular, [String? pluralForm]) =>
    '$count ${count == 1 ? singular : (pluralForm ?? '${singular}s')}';

/// Relative time for history rows: "just now", "5 min ago", "yesterday", "12 Mar".
String formatRelative(DateTime time, {DateTime? now}) {
  final n = now ?? DateTime.now();
  final diff = n.difference(time);
  if (diff.inSeconds < 45) return 'just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
  final days = DateTime(n.year, n.month, n.day)
      .difference(DateTime(time.year, time.month, time.day))
      .inDays;
  if (days == 0) return '${plural(diff.inHours, 'hour')} ago';
  if (days == 1) return 'yesterday';
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', //
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  final base = '${time.day} ${months[time.month - 1]}';
  return time.year == n.year ? base : '$base ${time.year}';
}

/// Pulls the first http(s) URL out of arbitrary text (shared text often has
/// a title in front of the link).
String? extractUrl(String? text) {
  if (text == null) return null;
  final match = RegExp(r'https?://[^\s<>"]+', caseSensitive: false)
      .firstMatch(text.trim());
  return match?.group(0);
}
