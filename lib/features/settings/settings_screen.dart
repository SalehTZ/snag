import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/app_info.dart';
import '../../core/platform_actions.dart';
import '../../core/theme/theme.dart';
import '../../data/providers.dart';
import '../../data/settings.dart';
import '../../engine/models.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../templates/templates_screen.dart';
import 'components_section.dart';
import 'support_card.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _seeds = [
    0xFF6750A4, 0xFF0B57D0, 0xFF00897B, 0xFF2E7D32, //
    0xFFF57C00, 0xFFD81B60, 0xFFE53935, 0xFF5D4037,
  ];

  static const _browsers = [
    'chrome', 'firefox', 'brave', 'edge', 'chromium', 'opera', 'vivaldi', //
    'safari',
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(settingsProvider);
    final n = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;

    void set(AppSettings Function(AppSettings) f) => n.update(f);

    return Scaffold(
      appBar: PageHeader(title: l.settingsTitle),
      body: ReadableWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 40),
          children: [
            // ------------------------------------------------ appearance
            SectionHeader(l.settingsAppearance),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: const Icon(Icons.brightness_auto_rounded),
                      label: Text(l.themeSystem)),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: const Icon(Icons.light_mode_rounded),
                      label: Text(l.themeLight)),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: const Icon(Icons.dark_mode_rounded),
                      label: Text(l.themeDark)),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) =>
                    set((s) => s.copyWith(themeMode: v.first)),
              ),
            ),
            LanguageTile(
              current: s.localeCode,
              onChanged: (code) =>
                  set((s) => s.copyWith(localeCode: () => code)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.palette_outlined),
              title: Text(l.settingsDynamicColor),
              subtitle: Text(l.settingsDynamicColorSubtitle),
              value: s.dynamicColor,
              onChanged: (v) => set((s) => s.copyWith(dynamicColor: v)),
            ),
            AnimatedOpacity(
              opacity: s.dynamicColor ? 0.4 : 1,
              duration: const Duration(milliseconds: 200),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                child: Wrap(spacing: 10, runSpacing: 10, children: [
                  for (final seed in _seeds)
                    _ColorDot(
                      color: Color(seed),
                      selected: !s.dynamicColor && s.seedColor == seed,
                      onTap: () => set((s) =>
                          s.copyWith(seedColor: seed, dynamicColor: false)),
                    ),
                ]),
              ),
            ),

            // ------------------------------------------------ downloads
            SectionHeader(l.settingsDownloads),
            _FolderTile(current: s.downloadDir),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: Text(l.settingsFileName),
              subtitle: Text(s.filenameTemplate,
                  textDirection: TextDirection.ltr, style: monoStyle),
              onTap: () async {
                final v = await _editText(
                  context,
                  title: l.settingsFileNameTemplate,
                  initial: s.filenameTemplate,
                  helper: l.settingsFileNameHelper,
                  monospace: true,
                );
                if (v != null) {
                  set((s) => s.copyWith(
                      filenameTemplate: v.trim().isEmpty
                          ? AppSettings.defaultFilenameTemplate
                          : v));
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.download_for_offline_outlined),
              title: Text(l.settingsDefaultType),
              trailing: SegmentedButton<DownloadMode>(
                showSelectedIcon: false,
                segments: [
                  ButtonSegment(
                      value: DownloadMode.video, label: Text(l.filterVideo)),
                  ButtonSegment(
                      value: DownloadMode.audio, label: Text(l.filterAudio)),
                ],
                selected: {s.defaultMode},
                onSelectionChanged: (v) =>
                    set((s) => s.copyWith(defaultMode: v.first)),
              ),
            ),
            _EnumTile<VideoQuality>(
              icon: Icons.high_quality_outlined,
              title: l.settingsDefaultQuality,
              value: s.defaultQuality,
              values: VideoQuality.values,
              label: l.quality,
              onChanged: (v) => set((s) => s.copyWith(defaultQuality: v)),
            ),
            _EnumTile<AudioFormat>(
              icon: Icons.audiotrack_outlined,
              title: l.settingsDefaultAudio,
              value: s.defaultAudioFormat,
              values: AudioFormat.values,
              label: l.audio,
              onChanged: (v) => set((s) => s.copyWith(defaultAudioFormat: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.devices_rounded),
              title: Text(l.settingsCompatible),
              subtitle: Text(l.settingsCompatibleSubtitle),
              value: s.preferCompatible,
              onChanged: (v) => set((s) => s.copyWith(preferCompatible: v)),
            ),
            ListTile(
              leading: const Icon(Icons.stacked_line_chart_rounded),
              title: Text(l.settingsConcurrency),
              subtitle: Slider(
                value: s.concurrency.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: context.fmt.digits(s.concurrency),
                onChanged: (v) =>
                    set((s) => s.copyWith(concurrency: v.round())),
              ),
              trailing: Text(context.fmt.digits(s.concurrency),
                  style: theme.textTheme.titleMedium),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.content_paste_search_rounded),
              title: Text(l.settingsClipboard),
              subtitle: Text(l.settingsClipboardSubtitle),
              value: s.autoPaste,
              onChanged: (v) => set((s) => s.copyWith(autoPaste: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.text_format_rounded),
              title: Text(l.settingsPlainNames),
              subtitle: Text(l.settingsPlainNamesSubtitle),
              value: s.restrictFilenames,
              onChanged: (v) => set((s) => s.copyWith(restrictFilenames: v)),
            ),

            // ------------------------------------------------ processing
            SectionHeader(l.settingsExtras),
            SwitchListTile(
              secondary: const Icon(Icons.label_outline_rounded),
              title: Text(l.settingsEmbedMetadata),
              subtitle: Text(l.settingsEmbedMetadataSubtitle),
              value: s.embedMetadata,
              onChanged: (v) => set((s) => s.copyWith(embedMetadata: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.image_outlined),
              title: Text(l.settingsEmbedThumbnail),
              subtitle: Text(l.settingsEmbedThumbnailSubtitle),
              value: s.embedThumbnail,
              onChanged: (v) => set((s) => s.copyWith(embedThumbnail: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.bookmarks_outlined),
              title: Text(l.settingsEmbedChapters),
              value: s.embedChapters,
              onChanged: (v) => set((s) => s.copyWith(embedChapters: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.subtitles_outlined),
              title: Text(l.settingsEmbedSubtitles),
              subtitle:
                  Text(l.settingsSubtitleLanguagesValue(s.subtitleLangs)),
              value: s.embedSubtitles,
              onChanged: (v) => set((s) => s.copyWith(embedSubtitles: v)),
            ),
            ListTile(
              leading: const SizedBox(width: 24),
              title: Text(l.settingsSubtitleLanguages),
              subtitle:
                  Text(s.subtitleLangs, textDirection: TextDirection.ltr),
              onTap: () async {
                final v = await _editText(context,
                    title: l.settingsSubtitleLanguages,
                    initial: s.subtitleLangs,
                    helper: l.settingsSubtitleLanguagesHelper,
                    monospace: true);
                if (v != null && v.trim().isNotEmpty) {
                  set((s) => s.copyWith(subtitleLangs: v.trim()));
                }
              },
            ),
            _EnumTile<SponsorBlockMode>(
              icon: Icons.content_cut_rounded,
              title: l.settingsSponsorBlock,
              subtitle: l.settingsSponsorBlockSubtitle,
              value: s.sponsorBlock,
              values: SponsorBlockMode.values,
              label: (m) => switch (m) {
                SponsorBlockMode.off => l.sponsorOff,
                SponsorBlockMode.mark => l.sponsorMark,
                SponsorBlockMode.remove => l.sponsorRemove,
              },
              onChanged: (v) => set((s) => s.copyWith(sponsorBlock: v)),
            ),

            // ------------------------------------------------ network
            SectionHeader(l.settingsNetwork),
            if (isDesktop)
              _EnumTile<String?>(
                icon: Icons.cookie_outlined,
                title: l.settingsBrowserCookies,
                subtitle: l.settingsBrowserCookiesSubtitle,
                value: s.cookiesFromBrowser,
                values: [null, ..._browsers],
                label: (b) => b == null
                    ? l.commonNone
                    : b[0].toUpperCase() + b.substring(1),
                onChanged: (v) =>
                    set((s) => s.copyWith(cookiesFromBrowser: () => v)),
              ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: Text(l.settingsCookiesFile),
              subtitle: Text(s.cookiesFile ?? l.settingsCookiesFileHint),
              trailing: s.cookiesFile == null
                  ? null
                  : IconButton(
                      tooltip: l.settingsCookiesRemove,
                      onPressed: () =>
                          set((s) => s.copyWith(cookiesFile: () => null)),
                      icon: const Icon(Icons.close_rounded),
                    ),
              onTap: () async {
                final file = await FilePicker.pickFile(
                    dialogTitle: l.settingsCookiesChoose);
                if (file == null) return;
                // Android hands back content:// URIs; keep a private copy.
                var path = file.path;
                if (path == null) {
                  final dir = await getApplicationSupportDirectory();
                  path = p.join(dir.path, 'cookies.txt');
                  await File(path).writeAsBytes(await file.readAsBytes());
                }
                final chosen = path;
                set((s) => s.copyWith(cookiesFile: () => chosen));
              },
            ),
            _TextTile(
              icon: Icons.vpn_lock_outlined,
              title: l.settingsProxy,
              value: s.proxy,
              empty: l.settingsNotSet,
              helper: l.settingsProxyHelper,
              monospace: true,
              onChanged: (v) => set((s) => s.copyWith(proxy: () => v)),
            ),
            _TextTile(
              icon: Icons.speed_rounded,
              title: l.settingsSpeedLimit,
              value: s.rateLimit,
              empty: l.settingsUnlimited,
              helper: l.settingsSpeedLimitHelper,
              monospace: true,
              onChanged: (v) => set((s) => s.copyWith(rateLimit: () => v)),
            ),
            if (isDesktop)
              SwitchListTile(
                secondary: const Icon(Icons.rocket_launch_outlined),
                title: Text(l.settingsAria2c),
                subtitle: Text(l.settingsAria2cSubtitle),
                value: s.useAria2c,
                onChanged: (v) => set((s) => s.copyWith(useAria2c: v)),
              ),

            // ------------------------------------------------ advanced
            SectionHeader(l.settingsPowerTools),
            ListTile(
              leading: const Icon(Icons.terminal_rounded),
              title: Text(l.settingsTemplates),
              subtitle: Text(l.settingsTemplatesSubtitle),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const TemplatesScreen())),
            ),
            _TextTile(
              icon: Icons.code_rounded,
              title: l.settingsExtraArgs,
              value: s.extraArgs.isEmpty ? null : s.extraArgs,
              empty: l.settingsExtraArgsEmpty,
              helper: l.settingsExtraArgsHelper,
              monospace: true,
              onChanged: (v) => set((s) => s.copyWith(extraArgs: v ?? '')),
            ),

            // ------------------------------------------------ components
            SectionHeader(l.settingsComponents),
            const ComponentsSection(),

            // ------------------------------------------------ about
            SectionHeader(l.settingsAbout),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SupportCard(),
            ),
            ListTile(
              leading: const Icon(Icons.translate_rounded),
              title: Text(l.settingsHelpTranslate(AppInfo.name)),
              subtitle: Text(l.settingsHelpTranslateSubtitle),
              onTap: () => PlatformActions.openLink(AppInfo.translateUrl),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text('${AppInfo.name} ${AppInfo.version}'),
              subtitle: Text(l.settingsAboutLicense),
            ),
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: Text(l.settingsSourceCode),
              subtitle: const Text(AppInfo.repoUrl,
                  textDirection: TextDirection.ltr),
              onTap: () => PlatformActions.openLink(AppInfo.repoUrl),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: Text(l.settingsReportProblem),
              onTap: () => PlatformActions.openLink(AppInfo.issuesUrl),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline_rounded),
              title: Text(l.settingsPoweredBy),
              subtitle: Text(l.settingsPoweredBySubtitle),
              onTap: () => PlatformActions.openLink(AppInfo.ytDlpUrl),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: Text(l.settingsLicenses),
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppInfo.name,
                applicationVersion: AppInfo.version,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                l.settingsLegal,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Every shipped translation, English first, then by native name. A
/// community-added ARB file shows up here with no code changes.
List<Locale> _languages() {
  String name(Locale l) => lookupAppLocalizations(l).languageNativeName;
  return [...AppLocalizations.supportedLocales]..sort((a, b) =>
      a.languageCode == 'en'
          ? -1
          : b.languageCode == 'en'
              ? 1
              : name(a).compareTo(name(b)));
}

String languageName(BuildContext context, String? code) => code == null
    ? context.l10n.settingsLanguageSystem
    : lookupAppLocalizations(Locale(code)).languageNativeName;

/// Shows the language list. Resolves to a 1-tuple so "System default"
/// (null) can be told apart from a dismissed dialog.
Future<(String?,)?> showLanguagePicker(BuildContext context, String? current) {
  return showDialog<(String?,)>(
    context: context,
    builder: (context) => SimpleDialog(
      title: Text(context.l10n.settingsLanguage),
      children: [
        RadioGroup<String?>(
          groupValue: current,
          onChanged: (v) => Navigator.pop(context, (v,)),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            for (final code in [null, for (final l in _languages()) l.languageCode])
              RadioListTile<String?>(
                value: code,
                title: Text(languageName(context, code)),
              ),
          ]),
        ),
      ],
    ),
  );
}

class LanguageTile extends StatelessWidget {
  const LanguageTile(
      {super.key, required this.current, required this.onChanged});

  final String? current;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.language_rounded),
      title: Text(context.l10n.settingsLanguage),
      subtitle: Text(languageName(context, current)),
      trailing: const Icon(Icons.unfold_more_rounded),
      onTap: () async {
        final picked = await showLanguagePicker(context, current);
        if (picked != null) onChanged(picked.$1);
      },
    );
  }
}

/// Compact version for the welcome screen.
class LanguageButton extends StatelessWidget {
  const LanguageButton(
      {super.key, required this.current, required this.onChanged});

  final String? current;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12)),
      onPressed: () async {
        final picked = await showLanguagePicker(context, current);
        if (picked != null) onChanged(picked.$1);
      },
      icon: const Icon(Icons.language_rounded, size: 20),
      label: Text(languageName(context, current)),
    );
  }
}

Future<String?> _editText(
  BuildContext context, {
  required String title,
  String? initial,
  String? helper,
  bool monospace = false,
}) {
  final controller = TextEditingController(text: initial);
  final l = context.l10n;
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: controller,
          autofocus: true,
          // Templates, proxies and flags are code: always left-to-right.
          textDirection: monospace ? TextDirection.ltr : null,
          style: monospace ? monoStyle : null,
          decoration: InputDecoration(helperText: helper, helperMaxLines: 3),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l.commonCancel)),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: Text(l.commonSave)),
      ],
    ),
  );
}

class _TextTile extends StatelessWidget {
  const _TextTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.empty,
    required this.onChanged,
    this.helper,
    this.monospace = false,
  });

  final IconData icon;
  final String title;
  final String? value;
  final String empty;
  final String? helper;
  final bool monospace;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final code = monospace && value != null;
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value ?? empty,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textDirection: code ? TextDirection.ltr : null,
          style: code ? monoStyle : null),
      onTap: () async {
        final v = await _editText(context,
            title: title, initial: value, helper: helper, monospace: monospace);
        if (v != null) onChanged(v.trim().isEmpty ? null : v.trim());
      },
    );
  }
}

class _EnumTile<T> extends StatelessWidget {
  const _EnumTile({
    required this.icon,
    required this.title,
    required this.value,
    required this.values,
    required this.label,
    required this.onChanged,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final T value;
  final List<T> values;
  final String Function(T) label;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(
          subtitle == null ? label(value) : '${label(value)} · $subtitle'),
      trailing: const Icon(Icons.unfold_more_rounded),
      onTap: () async {
        final picked = await showDialog<(T,)>(
          context: context,
          builder: (context) => SimpleDialog(
            title: Text(title),
            children: [
              RadioGroup<T>(
                groupValue: value,
                onChanged: (v) => Navigator.pop(context, (v as T,)),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  for (final v in values)
                    RadioListTile<T>(value: v, title: Text(label(v))),
                ]),
              ),
            ],
          ),
        );
        if (picked != null) onChanged(picked.$1);
      },
    );
  }
}

class _ColorDot extends StatelessWidget {
  const _ColorDot({
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      selected: selected,
      label: context.l10n.settingsAccentColor,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius:
                BorderRadius.circular(selected ? AppTheme.radiusSm : 22),
            border: Border.all(
              color: selected ? scheme.onSurface : Colors.transparent,
              width: 3,
            ),
          ),
          child: selected
              ? const Icon(Icons.check_rounded, color: Colors.white)
              : null,
        ),
      ),
    );
  }
}

class _FolderTile extends ConsumerWidget {
  const _FolderTile({required this.current});
  final String? current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final engine = ref.watch(engineProvider);
    final l = context.l10n;
    return FutureBuilder<String>(
      future:
          current == null ? engine.defaultDownloadDir() : Future.value(current),
      builder: (context, snap) => ListTile(
        leading: const Icon(Icons.folder_outlined),
        title: Text(l.settingsSaveTo),
        subtitle: Text(snap.data ?? '...', textDirection: TextDirection.ltr),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (current != null)
            IconButton(
              tooltip: l.settingsUseDefaultFolder,
              onPressed: () => ref
                  .read(settingsProvider.notifier)
                  .update((s) => s.copyWith(downloadDir: () => null)),
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          if (isDesktop && snap.data != null)
            IconButton(
              tooltip: l.settingsOpenFolder,
              onPressed: () => PlatformActions.openFolder(snap.data!),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
        ]),
        onTap: () async {
          final dir = await FilePicker.getDirectoryPath(
              dialogTitle: l.settingsChooseFolder);
          if (dir != null) {
            ref
                .read(settingsProvider.notifier)
                .update((s) => s.copyWith(downloadDir: () => dir));
          }
        },
      ),
    );
  }
}
