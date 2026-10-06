# Translating Snag

Snag speaks **English** and **فارسی (Persian)** today. Every other language comes from people like you, and you don't need to know Flutter or Git to help.

[![Translation status](https://hosted.weblate.org/widget/snag/multi-auto.svg)](https://hosted.weblate.org/engage/snag/)

## Translate on Weblate (easiest)

1. Open **[Snag on Hosted Weblate](https://hosted.weblate.org/engage/snag/)** and sign in (GitHub works, or just an email and a nickname).
2. Pick your language, or choose **Start new translation** if it isn't there yet.
3. Translate in your browser. Each string shows a note on where it appears.

Weblate sends your work to this repository as a pull request, with your name on the commits. Once it's merged, your language ships in the next release and appears in **Settings > Language**, with no code changes. Right-to-left languages are mirrored automatically.

You don't have to translate everything at once: anything left untranslated falls back to English, so a partial translation is still welcome. Start with **`languageNativeName`**, the name of your language written in your language (`Deutsch`, `Türkçe`). That's what the language picker shows; until it's translated, the picker shows the language code instead.

**Regional variants:** translate the plain language first (`Português`, `pt`). Add a variant such as `pt_BR` only for the strings that really differ; Snag can't build a variant without its plain language.

## Or edit the file directly

If you prefer Git, a translation is one file:

1. Copy `lib/l10n/app_en.arb` to `lib/l10n/app_<code>.arb`, where `<code>` is the [ISO 639-1 code](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) of your language, e.g. `app_de.arb`, `app_tr.arb` or `app_pt.arb`.
2. At the top, set `"@@locale": "<code>"` and translate `"languageNativeName"`.
3. Translate the values, not the keys. You can delete the lines that start with `"@` (notes for translators); they only matter in the English file.
4. Leave out strings you haven't translated rather than setting them to `""`, so they fall back to English.
5. Open a pull request. CI checks your file automatically.

If the language is already on Weblate, please use Weblate instead, so two people don't edit the same file at once.

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
- **"Snag"** is the app's name and is never translated; the home screen always shows "Snag." as the logo. The English word means "to grab or catch quickly", so:
  - `brandMeaning` is a tiny gloss shown next to the logo, telling people what the name means in your language (one or two words, e.g. `"schnappen"`).
  - `homeSnagButton` (the main button) can be a natural verb like "Get it" or "Grab it".

## Check your work locally (optional)

```bash
flutter gen-l10n        # regenerates lib/l10n/gen/
flutter test test/translations_test.dart
flutter run             # then pick your language in Settings
```

`test/translations_test.dart` checks that your file is named after its locale, has no blank strings or unknown keys, keeps every placeholder and has balanced braces. A regional file (`app_pt_BR.arb`) also needs its plain language (`app_pt.arb`).

## Help with the README

The README exists in [English](README.md) and [فارسی](README.fa.md). To add yours, copy `README.md` to `README.<code>.md`, translate it, and add a link to the language bar at the top of every README.

## A note on Material

Snag's buttons, dialogs and date pickers use Flutter's built-in translations, which cover [about 80 languages](https://api.flutter.dev/flutter/flutter_localizations/GlobalMaterialLocalizations-class.html). If yours isn't among them, open an issue first and we'll sort it out together.
