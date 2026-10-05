import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/theme.dart';
import '../../data/providers.dart';
import '../../data/records.dart';
import '../../engine/models.dart';
import '../../shell.dart';
import '../../widgets/common.dart';
import '../queue/download_manager.dart';

/// Shows download options for [info]. Resolves to true if anything was queued.
Future<bool?> showDownloadSheet(BuildContext context, MediaInfo info) {
  final wide = MediaQuery.sizeOf(context).width >= 720;
  if (wide) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        clipBehavior: Clip.antiAlias,
        insetPadding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 640,
            maxHeight: MediaQuery.sizeOf(context).height * 0.88,
          ),
          child: DownloadSheet(info: info, inDialog: true),
        ),
      ),
    );
  }
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (context, scroll) =>
          DownloadSheet(info: info, scrollController: scroll),
    ),
  );
}

class DownloadSheet extends ConsumerStatefulWidget {
  const DownloadSheet({
    super.key,
    required this.info,
    this.scrollController,
    this.inDialog = false,
  });

  final MediaInfo info;
  final ScrollController? scrollController;
  final bool inDialog;

  @override
  ConsumerState<DownloadSheet> createState() => _DownloadSheetState();
}

class _DownloadSheetState extends ConsumerState<DownloadSheet> {
  late DownloadMode _mode;
  late VideoQuality _quality;
  late AudioFormat _audio;
  late bool _subs;
  String? _formatId;
  String? _templateId;
  bool _advanced = false;
  late Set<int> _selected;

  MediaInfo get info => widget.info;

  @override
  void initState() {
    super.initState();
    final s = ref.read(settingsProvider);
    _mode = s.defaultMode;
    _audio = s.defaultAudioFormat;
    _subs = s.embedSubtitles;
    final options = _qualityOptions;
    _quality = options.contains(s.defaultQuality)
        ? s.defaultQuality
        : VideoQuality.best;
    _selected = {for (var i = 0; i < info.entries.length; i++) i};
  }

  List<VideoQuality> get _qualityOptions {
    final heights = info.availableHeights;
    if (heights.isEmpty) return VideoQuality.values;
    final max = heights.first;
    return VideoQuality.values
        .where((q) => q.height == null || q.height! <= max)
        .toList();
  }

  CommandTemplate? get _template => _templateId == null
      ? null
      : ref
          .read(templatesProvider)
          .where((t) => t.id == _templateId)
          .firstOrNull;

  DownloadSpec _spec(String url) {
    final t = _template;
    return DownloadSpec(
      url: url,
      mode: _mode,
      quality: _quality,
      audioFormat: _audio,
      formatId: t == null ? _formatId : null,
      subtitles: _subs,
      templateArgs: t?.args,
      templateName: t?.name,
    );
  }

  void _download() {
    final manager = ref.read(downloadManagerProvider.notifier);
    if (info.isPlaylist) {
      final items = [
        for (final i in _selected.toList()..sort())
          (_spec(info.entries[i].url), MediaMeta.fromEntry(info.entries[i])),
      ];
      if (items.isEmpty) return;
      manager.enqueueAll(items);
    } else {
      manager.enqueue(_spec(info.url), MediaMeta.fromInfo(info));
    }
    final count = info.isPlaylist ? _selected.length : 1;
    // Show via the root messenger before this route goes away; capture the
    // notifier because this widget is disposed by the time "View" is tapped.
    final tabs = ref.read(tabProvider.notifier);
    showSnack(
      context,
      count == 1 ? 'Added to the queue' : '${plural(count, 'item')} added to the queue',
      actionLabel: 'View',
      onAction: () => tabs.go(AppTab.queue),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final templates = ref.watch(templatesProvider);
    final usingTemplate = _template != null;
    final count = info.isPlaylist ? _selected.length : 1;

    final buttonLabel = info.isPlaylist
        ? (count == 0 ? 'Select something to download' : 'Download ${plural(count, 'item')}')
        : usingTemplate
            ? 'Download with template'
            : _mode == DownloadMode.audio
                ? 'Download audio'
                : 'Download video';

    final body = <Widget>[
      _Header(info: info),
      const SizedBox(height: 24),
      AnimatedOpacity(
        opacity: usingTemplate ? 0.4 : 1,
        duration: Motion.of(context, Motion.short),
        child: IgnorePointer(
          ignoring: usingTemplate,
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            SegmentedButton<DownloadMode>(
              segments: const [
                ButtonSegment(
                  value: DownloadMode.video,
                  icon: Icon(Icons.movie_rounded),
                  label: Text('Video'),
                ),
                ButtonSegment(
                  value: DownloadMode.audio,
                  icon: Icon(Icons.music_note_rounded),
                  label: Text('Audio only'),
                ),
              ],
              selected: {_mode},
              onSelectionChanged: (v) => setState(() {
                _mode = v.first;
                _formatId = null;
              }),
            ),
            const SizedBox(height: 20),
            Text(_mode == DownloadMode.video ? 'Quality' : 'Format',
                style: theme.textTheme.titleSmall),
            const SizedBox(height: 10),
            AnimatedSwitcher(
              duration: Motion.of(context, Motion.short),
              layoutBuilder: (current, previous) => Stack(
                alignment: Alignment.topLeft,
                children: [...previous, ?current],
              ),
              child: Wrap(
                key: ValueKey(_mode),
                spacing: 8,
                runSpacing: 8,
                children: _mode == DownloadMode.video
                    ? [
                        for (final q in _qualityOptions)
                          ChoiceChip(
                            label: Text(q.label),
                            selected: _formatId == null && _quality == q,
                            onSelected: (_) => setState(() {
                              _quality = q;
                              _formatId = null;
                            }),
                          ),
                      ]
                    : [
                        for (final a in AudioFormat.values)
                          ChoiceChip(
                            label: Text(a == AudioFormat.best ? 'Original' : a.label),
                            selected: _formatId == null && _audio == a,
                            onSelected: (_) => setState(() {
                              _audio = a;
                              _formatId = null;
                            }),
                          ),
                      ],
              ),
            ),
            if (_mode == DownloadMode.video &&
                (info.isPlaylist || info.subtitleLangs.isNotEmpty)) ...[
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                value: _subs,
                onChanged: (v) => setState(() => _subs = v),
                title: const Text('Embed subtitles'),
                subtitle: Text(info.isPlaylist
                    ? 'When the video has them'
                    : 'Available: ${_langSummary(info.subtitleLangs)}'),
              ),
            ],
          ]),
        ),
      ),
      if (info.isPlaylist) ...[
        const SizedBox(height: 16),
        _PlaylistPicker(
          entries: info.entries,
          selected: _selected,
          onChanged: (s) => setState(() => _selected = s),
        ),
      ],
      const SizedBox(height: 8),
      _AdvancedToggle(
        open: _advanced,
        onTap: () => setState(() => _advanced = !_advanced),
      ),
      AnimatedSize(
        duration: Motion.of(context, Motion.medium),
        curve: Motion.spatial,
        alignment: Alignment.topCenter,
        child: !_advanced
            ? const SizedBox(width: double.infinity)
            : Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                if (templates.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: _templateId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Command template',
                      helperText: 'Replaces the options above with your own yt-dlp flags',
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('None')),
                      for (final t in templates)
                        DropdownMenuItem(
                          value: t.id,
                          child: Text(t.name, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _templateId = v),
                  ),
                ],
                if (!info.isPlaylist && info.formats.isNotEmpty && !usingTemplate) ...[
                  const SizedBox(height: 16),
                  _FormatPicker(
                    formats: info.formats,
                    mode: _mode,
                    selected: _formatId,
                    onChanged: (id) => setState(() => _formatId = id),
                  ),
                ],
              ]),
      ),
    ];

    final button = Padding(
      padding: EdgeInsets.fromLTRB(24, 12, 24, widget.inDialog ? 24 : 16),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: FilledButton.icon(
          onPressed: count == 0 ? null : _download,
          icon: const Icon(Icons.download_rounded),
          label: Text(buttonLabel, textAlign: TextAlign.center),
        ),
      ),
    );

    return Material(
      type: MaterialType.transparency,
      child: Column(children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: EdgeInsets.fromLTRB(24, widget.inDialog ? 24 : 0, 24, 8),
            children: body,
          ),
        ),
        SafeArea(top: false, child: button),
      ]),
    );
  }

  static String _langSummary(List<String> langs) {
    if (langs.length <= 4) return langs.join(', ');
    return '${langs.take(4).join(', ')} and ${langs.length - 4} more';
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.info});
  final MediaInfo info;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final meta = [
      if (info.uploader != null) info.uploader!,
      if (info.isPlaylist) plural(info.entries.length, 'item'),
      if (info.extractor != null) info.extractor!,
    ].join(' · ');
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (info.thumbnail != null || !info.isPlaylist)
        LayoutBuilder(
          builder: (context, c) => MediaThumb(
            url: info.thumbnail,
            width: c.maxWidth,
            radius: AppTheme.radiusLg,
            duration: info.duration,
            icon: info.isPlaylist
                ? Icons.playlist_play_rounded
                : Icons.movie_outlined,
          ),
        ),
      const SizedBox(height: 16),
      if (info.isPlaylist)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text('PLAYLIST',
              style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.primary, letterSpacing: 1.2)),
        ),
      // Primary content: wraps, never truncates.
      SelectableText(info.title, style: theme.textTheme.titleLarge),
      if (meta.isNotEmpty) ...[
        const SizedBox(height: 4),
        Text(meta,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant)),
      ],
    ]);
  }
}

class _AdvancedToggle extends StatelessWidget {
  const _AdvancedToggle({required this.open, required this.onTap});
  final bool open;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: onTap,
        icon: AnimatedRotation(
          turns: open ? 0.5 : 0,
          duration: Motion.of(context, Motion.medium),
          curve: Motion.spatial,
          child: const Icon(Icons.expand_more_rounded),
        ),
        label: Text(open ? 'Fewer options' : 'More options'),
      ),
    );
  }
}

class _FormatPicker extends StatelessWidget {
  const _FormatPicker({
    required this.formats,
    required this.mode,
    required this.selected,
    required this.onChanged,
  });

  final List<MediaFormat> formats;
  final DownloadMode mode;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shown = mode == DownloadMode.audio
        ? formats.where((f) => f.hasAudio && !f.hasVideo).toList()
        : formats.where((f) => f.hasVideo).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

    // Video-only streams get the best audio merged in automatically.
    String selectorFor(MediaFormat f) =>
        f.hasVideo && !f.hasAudio ? '${f.id}+ba/${f.id}' : f.id;

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Exact format', style: theme.textTheme.titleSmall),
      const SizedBox(height: 4),
      Text(
        'For when you know exactly what you want. Overrides the quality above.',
        style: theme.textTheme.bodySmall
            ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      const SizedBox(height: 8),
      Container(
        constraints: const BoxConstraints(maxHeight: 280),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        child: RadioGroup<String?>(
          groupValue: selected,
          onChanged: onChanged,
          child: ListView(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 4),
            children: [
              for (final f in shown)
                RadioListTile<String?>(
                  dense: true,
                  value: selectorFor(f),
                  title: Text(f.label),
                  subtitle: Text([
                    if (f.filesize != null) formatBytes(f.filesize),
                    if (f.hasVideo && !f.hasAudio) 'audio added automatically',
                    'id ${f.id}',
                  ].join(' · ')),
                ),
            ],
          ),
        ),
      ),
      if (selected != null)
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => onChanged(null),
            child: const Text('Use the quality preset instead'),
          ),
        ),
    ]);
  }
}

class _PlaylistPicker extends StatelessWidget {
  const _PlaylistPicker({
    required this.entries,
    required this.selected,
    required this.onChanged,
  });

  final List<PlaylistEntry> entries;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final all = selected.length == entries.length;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
          child: Text('${selected.length} of ${entries.length} selected',
              style: theme.textTheme.titleSmall),
        ),
        TextButton(
          onPressed: () => onChanged(
              all ? <int>{} : {for (var i = 0; i < entries.length; i++) i}),
          child: Text(all ? 'Select none' : 'Select all'),
        ),
      ]),
      const SizedBox(height: 4),
      Container(
        constraints: const BoxConstraints(maxHeight: 360),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        ),
        clipBehavior: Clip.antiAlias,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: entries.length,
          itemBuilder: (context, i) {
            final e = entries[i];
            return CheckboxListTile(
              dense: true,
              value: selected.contains(i),
              onChanged: (v) {
                final next = {...selected};
                v == true ? next.add(i) : next.remove(i);
                onChanged(next);
              },
              controlAffinity: ListTileControlAffinity.leading,
              title: Text(e.title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text([
                '#${i + 1}',
                if (e.duration != null) formatDuration(e.duration),
                if (e.uploader != null) e.uploader!,
              ].join(' · ')),
            );
          },
        ),
      ),
    ]);
  }
}
