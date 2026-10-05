# Contributing to Snag

Thanks for helping! A few ground rules keep Snag small and pleasant.

## Before you start

- **A site is broken?** Update yt-dlp first (Settings > Components > Update, or turn on nightly). Most breakages are fixed upstream in [yt-dlp](https://github.com/yt-dlp/yt-dlp) and are not Snag bugs.
- **A big feature?** Open an issue first, so we agree on the shape before you spend time on it. Snag's main promise is "one box, one button". Power features belong behind "More options" or in Settings.

## Development

```bash
flutter pub get
flutter analyze          # must be clean
flutter test             # unit tests
flutter test tool/e2e    # real downloads on desktop (network)
flutter test tool/screenshots --update-goldens   # look at every screen after UI changes
```

- All yt-dlp flags are built in `lib/engine/args_builder.dart`. If you add a flag, add a test in `test/args_builder_test.dart`.
- Output parsing lives in one place (`lib/engine/output_parser.dart`). Keep platform code (Kotlin, desktop process) dumb: it only forwards lines.
- Follow the existing style: Riverpod `Notifier`s, theme tokens instead of raw colors, `Motion` springs for movement, and empty/error states for every screen.
- Visible copy is plain and friendly. Errors say what to do next.

## Commits and PRs

- Keep PRs focused. Describe what changed and how you tested it. Include before/after screenshots for UI changes.
- By contributing, you agree your work is licensed under GPL-3.0.
