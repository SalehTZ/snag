# Translating Snag

Snag speaks **English** and **فارسی (Persian)** today. Every other language comes from people like you, and you don't need to know Flutter to help.

## Add a new language (one file)

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<code>.arb`, where `<code>` is the [ISO 639-1 code](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) of your language, e.g. `app_de.arb`, `app_tr.arb` or `app_pt.arb`.
2. At the top, set `"@@locale": "<code>"`, and set `"languageNativeName"` to the name of your language **written in your language** (`"Deutsch"`, `"Türkçe"`). That's what the language picker shows.
3. Translate the values, not the keys. Delete every line that starts with `"@` (those are notes for translators and only belong in the English file).
4. Open a pull request. CI checks your file automatically.

That's it. The new language appears in **Settings > Language** with no code changes. Right-to-left languages are mirrored automatically.

You don't have to translate everything at once: anything you leave out falls back to English, so a partial translation is still welcome.

## Rules of thumb

- **Keep `{placeholders}` exactly as they are.** Move them around freely, but don't translate the names inside the braces:
  `"Downloading ({count})"` → `"Wird heruntergeladen ({count})"`
- **Plurals** use ICU syntax. Use the plural categories your language needs:
  ```json
  "itemCount": "{count, plural, =1{1 Element} other{{count} Elemente}}"
  ```
  Languages without grammatical plurals (Persian, Turkish, Japanese...) can use only `other`:
  ```json
  "itemCount": "{count, plural, other{{count} مورد}}"
  ```
- **Leave product and technical names alone:** Snag, yt-dlp, ffmpeg, Deno, SponsorBlock, MP4, H.264, cookies.txt.
  In the ARB files `yt-dlp` is written `yt\u2060-\u2060dlp`. The invisible "word joiners" stop it from breaking across two lines. Copy it as is.
- **Be short and friendly.** Buttons are small. Errors should say what to do next.
- **"Snag"** is the app's name and also means "to grab". Translate the button/headline as a natural verb ("Get it", "Grab it"); keep the app name itself.

## Check your work locally (optional)

```bash
flutter gen-l10n        # regenerates lib/l10n/gen/
flutter test test/translations_test.dart
flutter run             # then pick your language in Settings
```

`test/translations_test.dart` checks that your file declares its locale and native name, has no unknown keys, keeps every placeholder and has balanced braces.

## Help with the README

The README exists in [English](README.md) and [فارسی](README.fa.md). To add yours, copy `README.md` to `README.<code>.md`, translate it, and add a link to the language bar at the top of every README.

## A note on Material

Snag's buttons, dialogs and date pickers use Flutter's built-in translations, which cover [about 80 languages](https://api.flutter.dev/flutter/flutter_localizations/GlobalMaterialLocalizations-class.html). If yours isn't among them, open an issue first and we'll sort it out together.
