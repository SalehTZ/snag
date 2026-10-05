/// Locale-free text helpers. Anything shown to users is formatted by
/// `Fmt` in lib/l10n/l10n.dart instead.
library;

/// Pulls the first http(s) URL out of arbitrary text (shared text often has
/// a title in front of the link).
String? extractUrl(String? text) {
  if (text == null) return null;
  final match = RegExp(r'https?://[^\s<>"]+', caseSensitive: false)
      .firstMatch(text.trim());
  return match?.group(0);
}
