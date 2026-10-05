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

    void set(AppSettings Function(AppSettings) f) => n.update(f);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ReadableWidth(
        maxWidth: 760,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 40),
          children: [
            // ------------------------------------------------ appearance
            const SectionHeader('Appearance'),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.brightness_auto_rounded),
                      label: Text('System')),
                  ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_rounded),
                      label: Text('Light')),
                  ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_rounded),
                      label: Text('Dark')),
                ],
                selected: {s.themeMode},
                onSelectionChanged: (v) =>
                    set((s) => s.copyWith(themeMode: v.first)),
              ),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.palette_outlined),
              title: const Text('Colors from your system'),
              subtitle: const Text('Match your wallpaper or accent color'),
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
            const SectionHeader('Downloads'),
            _FolderTile(current: s.downloadDir),
            ListTile(
              leading: const Icon(Icons.drive_file_rename_outline_rounded),
              title: const Text('File name'),
              subtitle: Text(s.filenameTemplate,
                  style: const TextStyle(fontFamily: 'monospace')),
              onTap: () async {
                final v = await _editText(
                  context,
                  title: 'File name template',
                  initial: s.filenameTemplate,
                  helper: 'yt-dlp output template, e.g. %(uploader)s - %(title)s.%(ext)s',
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
              title: const Text('Default type'),
              trailing: SegmentedButton<DownloadMode>(
                showSelectedIcon: false,
                segments: const [
                  ButtonSegment(value: DownloadMode.video, label: Text('Video')),
                  ButtonSegment(value: DownloadMode.audio, label: Text('Audio')),
                ],
                selected: {s.defaultMode},
                onSelectionChanged: (v) =>
                    set((s) => s.copyWith(defaultMode: v.first)),
              ),
            ),
            _EnumTile<VideoQuality>(
              icon: Icons.high_quality_outlined,
              title: 'Default video quality',
              value: s.defaultQuality,
              values: VideoQuality.values,
              label: (q) => q.label,
              onChanged: (v) => set((s) => s.copyWith(defaultQuality: v)),
            ),
            _EnumTile<AudioFormat>(
              icon: Icons.audiotrack_outlined,
              title: 'Default audio format',
              value: s.defaultAudioFormat,
              values: AudioFormat.values,
              label: (a) => a == AudioFormat.best ? 'Original' : a.label,
              onChanged: (v) => set((s) => s.copyWith(defaultAudioFormat: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.devices_rounded),
              title: const Text('Prefer formats that play everywhere'),
              subtitle: const Text('H.264 + AAC in MP4 when available'),
              value: s.preferCompatible,
              onChanged: (v) => set((s) => s.copyWith(preferCompatible: v)),
            ),
            ListTile(
              leading: const Icon(Icons.stacked_line_chart_rounded),
              title: const Text('Downloads at the same time'),
              subtitle: Slider(
                value: s.concurrency.toDouble(),
                min: 1,
                max: 5,
                divisions: 4,
                label: '${s.concurrency}',
                onChanged: (v) =>
                    set((s) => s.copyWith(concurrency: v.round())),
              ),
              trailing: Text('${s.concurrency}',
                  style: theme.textTheme.titleMedium),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.content_paste_search_rounded),
              title: const Text('Spot links in the clipboard'),
              subtitle: const Text('Offer to paste a copied link on the Snag tab'),
              value: s.autoPaste,
              onChanged: (v) => set((s) => s.copyWith(autoPaste: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.text_format_rounded),
              title: const Text('Plain file names'),
              subtitle: const Text('ASCII only, no spaces or special characters'),
              value: s.restrictFilenames,
              onChanged: (v) => set((s) => s.copyWith(restrictFilenames: v)),
            ),

            // ------------------------------------------------ processing
            const SectionHeader('Extras'),
            SwitchListTile(
              secondary: const Icon(Icons.label_outline_rounded),
              title: const Text('Embed metadata'),
              subtitle: const Text('Title, artist, date and description'),
              value: s.embedMetadata,
              onChanged: (v) => set((s) => s.copyWith(embedMetadata: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.image_outlined),
              title: const Text('Embed thumbnail'),
              subtitle: const Text('Shows as cover art in players'),
              value: s.embedThumbnail,
              onChanged: (v) => set((s) => s.copyWith(embedThumbnail: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.bookmarks_outlined),
              title: const Text('Embed chapters'),
              value: s.embedChapters,
              onChanged: (v) => set((s) => s.copyWith(embedChapters: v)),
            ),
            SwitchListTile(
              secondary: const Icon(Icons.subtitles_outlined),
              title: const Text('Embed subtitles by default'),
              subtitle: Text('Languages: ${s.subtitleLangs}'),
              value: s.embedSubtitles,
              onChanged: (v) => set((s) => s.copyWith(embedSubtitles: v)),
            ),
            ListTile(
              leading: const SizedBox(width: 24),
              title: const Text('Subtitle languages'),
              subtitle: Text(s.subtitleLangs),
              onTap: () async {
                final v = await _editText(context,
                    title: 'Subtitle languages',
                    initial: s.subtitleLangs,
                    helper: 'Comma separated, regex allowed: en.*,fa,de');
                if (v != null && v.trim().isNotEmpty) {
                  set((s) => s.copyWith(subtitleLangs: v.trim()));
                }
              },
            ),
            _EnumTile<SponsorBlockMode>(
              icon: Icons.content_cut_rounded,
              title: 'SponsorBlock',
              subtitle: 'Skip sponsor segments in YouTube videos',
              value: s.sponsorBlock,
              values: SponsorBlockMode.values,
              label: (m) => switch (m) {
                SponsorBlockMode.off => 'Off',
                SponsorBlockMode.mark => 'Mark as chapters',
                SponsorBlockMode.remove => 'Cut them out',
              },
              onChanged: (v) => set((s) => s.copyWith(sponsorBlock: v)),
            ),

            // ------------------------------------------------ network
            const SectionHeader('Network and sign-in'),
            if (isDesktop)
              _EnumTile<String?>(
                icon: Icons.cookie_outlined,
                title: 'Use cookies from browser',
                subtitle: 'Fixes "sign in to confirm you\'re not a bot" and private videos',
                value: s.cookiesFromBrowser,
                values: [null, ..._browsers],
                label: (b) => b == null ? 'None' : b[0].toUpperCase() + b.substring(1),
                onChanged: (v) => set((s) => s.copyWith(cookiesFromBrowser: () => v)),
              ),
            ListTile(
              leading: const Icon(Icons.description_outlined),
              title: const Text('Cookies file'),
              subtitle: Text(s.cookiesFile ?? 'Netscape-format cookies.txt'),
              trailing: s.cookiesFile == null
                  ? null
                  : IconButton(
                      tooltip: 'Remove cookies file',
                      onPressed: () =>
                          set((s) => s.copyWith(cookiesFile: () => null)),
                      icon: const Icon(Icons.close_rounded),
                    ),
              onTap: () async {
                final file =
                    await FilePicker.pickFile(dialogTitle: 'Choose cookies.txt');
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
              title: 'Proxy',
              value: s.proxy,
              empty: 'Not set',
              helper: 'e.g. socks5://127.0.0.1:1080 or http://host:port',
              onChanged: (v) => set((s) => s.copyWith(proxy: () => v)),
            ),
            _TextTile(
              icon: Icons.speed_rounded,
              title: 'Speed limit',
              value: s.rateLimit,
              empty: 'Unlimited',
              helper: 'Bytes per second, e.g. 2M or 500K',
              onChanged: (v) => set((s) => s.copyWith(rateLimit: () => v)),
            ),
            if (isDesktop)
              SwitchListTile(
                secondary: const Icon(Icons.rocket_launch_outlined),
                title: const Text('Use aria2c'),
                subtitle: const Text('Faster multi-connection downloads (aria2c must be installed)'),
                value: s.useAria2c,
                onChanged: (v) => set((s) => s.copyWith(useAria2c: v)),
              ),

            // ------------------------------------------------ advanced
            const SectionHeader('Power tools'),
            ListTile(
              leading: const Icon(Icons.terminal_rounded),
              title: const Text('Command templates'),
              subtitle: const Text('Saved sets of raw yt-dlp flags'),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => const TemplatesScreen())),
            ),
            _TextTile(
              icon: Icons.code_rounded,
              title: 'Extra arguments',
              value: s.extraArgs.isEmpty ? null : s.extraArgs,
              empty: 'Added to every download',
              helper: 'Raw yt-dlp flags, e.g. --no-part --geo-bypass',
              monospace: true,
              onChanged: (v) => set((s) => s.copyWith(extraArgs: v ?? '')),
            ),

            // ------------------------------------------------ components
            const SectionHeader('Components'),
            const ComponentsSection(),

            // ------------------------------------------------ about
            const SectionHeader('About'),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: SupportCard(),
            ),
            ListTile(
              leading: const Icon(Icons.info_outline_rounded),
              title: Text('${AppInfo.name} ${AppInfo.version}'),
              subtitle: const Text('Free and open source, GPL-3.0'),
            ),
            ListTile(
              leading: const Icon(Icons.code_rounded),
              title: const Text('Source code'),
              subtitle: const Text(AppInfo.repoUrl),
              onTap: () => PlatformActions.openLink(AppInfo.repoUrl),
            ),
            ListTile(
              leading: const Icon(Icons.bug_report_outlined),
              title: const Text('Report a problem'),
              onTap: () => PlatformActions.openLink(AppInfo.issuesUrl),
            ),
            ListTile(
              leading: const Icon(Icons.favorite_outline_rounded),
              title: const Text('Powered by yt-dlp'),
              subtitle: const Text('The real hero. Go star it.'),
              onTap: () => PlatformActions.openLink(AppInfo.ytDlpUrl),
            ),
            ListTile(
              leading: const Icon(Icons.gavel_rounded),
              title: const Text('Open source licenses'),
              onTap: () => showLicensePage(
                context: context,
                applicationName: AppInfo.name,
                applicationVersion: AppInfo.version,
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                'Please only download what you have the right to.',
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

Future<String?> _editText(
  BuildContext context, {
  required String title,
  String? initial,
  String? helper,
  bool monospace = false,
}) {
  final controller = TextEditingController(text: initial);
  return showDialog<String>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: 480,
        child: TextField(
          controller: controller,
          autofocus: true,
          style: monospace ? const TextStyle(fontFamily: 'monospace') : null,
          decoration: InputDecoration(helperText: helper, helperMaxLines: 3),
          onSubmitted: (v) => Navigator.pop(context, v),
        ),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel')),
        FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Save')),
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
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      subtitle: Text(value ?? empty,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: monospace && value != null
              ? const TextStyle(fontFamily: 'monospace')
              : null),
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
      subtitle: Text(subtitle == null ? label(value) : '${label(value)} · $subtitle'),
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
      label: 'Accent color',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(selected ? AppTheme.radiusSm : 22),
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
    return FutureBuilder<String>(
      future: current == null ? engine.defaultDownloadDir() : Future.value(current),
      builder: (context, snap) => ListTile(
        leading: const Icon(Icons.folder_outlined),
        title: const Text('Save to'),
        subtitle: Text(snap.data ?? '...'),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
          if (current != null)
            IconButton(
              tooltip: 'Use the default folder',
              onPressed: () => ref
                  .read(settingsProvider.notifier)
                  .update((s) => s.copyWith(downloadDir: () => null)),
              icon: const Icon(Icons.restart_alt_rounded),
            ),
          if (isDesktop && snap.data != null)
            IconButton(
              tooltip: 'Open folder',
              onPressed: () => PlatformActions.openFolder(snap.data!),
              icon: const Icon(Icons.open_in_new_rounded),
            ),
        ]),
        onTap: () async {
          final dir = await FilePicker.getDirectoryPath(
              dialogTitle: 'Where should downloads go?');
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
