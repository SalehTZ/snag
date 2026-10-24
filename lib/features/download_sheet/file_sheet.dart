import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import '../../core/theme/theme.dart';
import '../../data/providers.dart';
import '../../data/settings.dart';
import '../../engine/aria2.dart';
import '../../engine/file_probe.dart';
import '../../engine/models.dart';
import '../../engine/ytdlp_engine.dart';
import '../../l10n/l10n.dart';
import '../../shell.dart';
import '../../widgets/common.dart';
import '../queue/download_manager.dart';

/// A plain file: its name, size and host, and one button. Resolves to true
/// if it was queued.
Future<bool?> showFileSheet(BuildContext context, RemoteFile file) {
  if (MediaQuery.sizeOf(context).width >= 720) {
    return showDialog<bool>(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: FileSheet(file: file, inDialog: true),
        ),
      ),
    );
  }
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => FileSheet(file: file),
  );
}

class FileSheet extends ConsumerStatefulWidget {
  const FileSheet({super.key, required this.file, this.inDialog = false});

  final RemoteFile file;
  final bool inDialog;

  @override
  ConsumerState<FileSheet> createState() => _FileSheetState();
}

class _FileSheetState extends ConsumerState<FileSheet> {
  late final Aria2 _aria2;
  late final AppSettings _settings;

  /// A torrent's files, once aria2 has read them; null while it reads.
  List<TorrentFile>? _files;
  bool _filesFailed = false;
  Set<int> _selected = {};

  RemoteFile get file => widget.file;

  @override
  void initState() {
    super.initState();
    _aria2 = ref.read(aria2Provider);
    _settings = ref.read(settingsProvider);
    if (!isTorrent(file.url)) return;
    // Picking is optional: Download works for everything while this runs.
    _aria2
        .torrentFiles(file.url, _settings)
        .then(
          (files) {
            if (!mounted) return;
            setState(() {
              _files = files;
              _selected = {for (final f in files) f.index};
            });
          },
          onError: (Object e) {
            if (mounted && e is! CancelledException) {
              setState(() => _filesFailed = true);
            }
          },
        );
  }

  @override
  void dispose() {
    unawaited(_aria2.stopFiles(file.url, _settings));
    super.dispose();
  }

  Future<void> _download() async {
    final files = _files;
    final some = files != null && _selected.length < files.length;
    // The probe holds the torrent's info hash; aria2 refuses a second one.
    await _aria2.stopFiles(file.url, _settings);
    if (!mounted) return;
    ref
        .read(downloadManagerProvider.notifier)
        .enqueue(
          DownloadSpec(
            url: file.url,
            kind: DownloadKind.file,
            files: some ? (_selected.toList()..sort()) : null,
          ),
          MediaMeta(title: file.name, uploader: file.host),
        );
    // Same hand-off as the media sheet: the root messenger outlives this route.
    final tabs = ref.read(tabProvider.notifier);
    final l = context.l10n;
    showSnack(
      context,
      l.commonAddedToQueue,
      actionLabel: l.commonView,
      onAction: () => tabs.go(AppTab.queue),
    );
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final files = _files;
    final picking = files != null && files.length > 1;
    final size = picking ? files.fold(0, (sum, f) => sum + f.size) : file.size;
    final meta = [
      if (size != null) context.fmt.bytes(size),
      if (file.host.isNotEmpty) file.host,
    ].join(' · ');
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: scheme.onSurfaceVariant,
      fontFeatures: const [FontFeature.tabularFigures()],
    );

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          24,
          widget.inDialog ? 24 : 0,
          24,
          widget.inDialog ? 24 : 16,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isTorrent(file.url) ? l.summaryTorrent : l.summaryFile,
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.primary,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            // Primary content: wraps, never truncates.
            SizedBox(
              width: double.infinity,
              child: SelectableText(
                file.name,
                textDirection: contentDirection(file.name),
                style: theme.textTheme.titleLarge,
              ),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(meta, style: muted),
            ],
            if (isTorrent(file.url) && files == null) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  if (!_filesFailed) ...[
                    const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    child: Text(
                      _filesFailed
                          ? l.sheetTorrentFilesFailed
                          : l.sheetTorrentReadingFiles,
                      style: muted,
                    ),
                  ),
                ],
              ),
            ],
            if (picking) ...[
              const SizedBox(height: 20),
              Flexible(
                child: _TorrentFilePicker(
                  files: files,
                  selected: _selected,
                  onChanged: (s) => setState(() => _selected = s),
                ),
              ),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton.icon(
                onPressed: picking && _selected.isEmpty ? null : _download,
                icon: const Icon(Icons.download_rounded),
                label: Text(
                  !picking
                      ? l.sheetDownloadFile
                      : _selected.isEmpty
                      ? l.sheetSelectSomething
                      : l.sheetDownloadFiles(_selected.length),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Checkboxes over a torrent's files, laid out like the playlist picker.
class _TorrentFilePicker extends StatelessWidget {
  const _TorrentFilePicker({
    required this.files,
    required this.selected,
    required this.onChanged,
  });

  final List<TorrentFile> files;
  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l = context.l10n;
    final fmt = context.fmt;
    final all = selected.length == files.length;
    final bytes = files
        .where((f) => selected.contains(f.index))
        .fold(0, (sum, f) => sum + f.size);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${l.sheetSelectedOf(selected.length, files.length)} · '
                '${fmt.bytes(bytes)}',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ),
            TextButton(
              onPressed: () =>
                  onChanged(all ? <int>{} : {for (final f in files) f.index}),
              child: Text(all ? l.sheetSelectNone : l.sheetSelectAll),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Flexible(
          // A Material, not a coloured box, so the rows' ink shows.
          child: Material(
            color: theme.colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppTheme.radiusMd),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 360),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: files.length,
                itemBuilder: (context, i) {
                  final f = files[i];
                  final name = p.basename(f.path);
                  final folder = p.dirname(f.path);
                  return CheckboxListTile(
                    dense: true,
                    value: selected.contains(f.index),
                    onChanged: (v) {
                      final next = {...selected};
                      v == true ? next.add(f.index) : next.remove(f.index);
                      onChanged(next);
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    title: Text(
                      name,
                      textDirection: contentDirection(name),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      [
                        fmt.bytes(f.size),
                        if (folder != '.') folder,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }
}
