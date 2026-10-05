# Contributing to Snag

Thanks for helping! A few ground rules keep Snag small and pleasant.

## Before you start

- **A site is broken?** Update yt-dlp first (Settings > Components > Update, or turn on nightly). Most breakages are fixed upstream in [yt-dlp](https://github.com/yt-dlp/yt-dlp) and are not Snag bugs.
- **A big feature?** Open an issue first, so we agree on the shape before you spend time on it. Snag's main promise is "one box, one button". Power features belong behind "More options" or in Settings.

## Translations

Adding or improving a language is a great first contribution and needs no Flutter knowledge. See [TRANSLATING.md](TRANSLATING.md).

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
- **No hard-coded UI text.** Add the string to `lib/l10n/app_en.arb` (and `app_fa.arb`, which must stay complete), then use `context.l10n.yourKey`. Numbers, sizes and dates go through `context.fmt` so every locale gets its own digits and calendar.
- Use `EdgeInsetsDirectional`/`AlignmentDirectional` (start/end, not left/right) so right-to-left languages mirror correctly. Links, paths and flags stay `TextDirection.ltr`.

## Releasing

1. Bump `version:` in `pubspec.yaml` (for example `0.1.1+2`; the number after `+` must always go up for Android updates).
2. Add a `## 0.1.1 - <date>` section to [CHANGELOG.md](CHANGELOG.md): what's new, in plain words.
3. Merge to `main`, then tag it: `git tag v0.1.1 && git push origin v0.1.1`.
4. The Release workflow builds every platform and creates a **draft** release with the files, the changelog section, a download table and checksums. Read it over on the Releases page and click **Publish release**.

The workflow refuses a tag that doesn't match `pubspec.yaml` or has no changelog section, within seconds. To redo a release that is still a draft, delete the draft, then move the tag: `git tag -f v0.1.1 && git push -f origin v0.1.1`. Once a release is published, never move its tag; release a new version instead.

## Commits and PRs

- Keep PRs focused. Describe what changed and how you tested it. Include before/after screenshots for UI changes.
- By contributing, you agree your work is licensed under GPL-3.0.
