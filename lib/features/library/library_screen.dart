import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/platform_actions.dart';
import '../../data/providers.dart';
import '../../data/records.dart';
import '../../engine/models.dart';
import '../../shell.dart';
import '../../widgets/common.dart';
import 'library_actions.dart';

enum _Filter { all, video, audio }

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key});

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  final _search = TextEditingController();
  _Filter _filter = _Filter.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<HistoryItem> _apply(List<HistoryItem> items) {
    final q = _search.text.trim().toLowerCase();
    return items.where((h) {
      if (_filter == _Filter.video && h.spec.mode != DownloadMode.video) {
        return false;
      }
      if (_filter == _Filter.audio && h.spec.mode != DownloadMode.audio) {
        return false;
      }
      if (q.isEmpty) return true;
      return h.title.toLowerCase().contains(q) ||
          (h.meta.uploader?.toLowerCase().contains(q) ?? false) ||
          h.spec.url.toLowerCase().contains(q);
    }).toList();
  }

  void _clearFilters() => setState(() {
        _search.clear();
        _filter = _Filter.all;
      });

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(historyProvider);
    final items = _apply(all);
    final filtering = _search.text.isNotEmpty || _filter != _Filter.all;

    Widget body;
    if (all.isEmpty) {
      // First run: invite, don't scold.
      body = EmptyState(
        icon: Icons.video_library_rounded,
        title: 'Your library is empty',
        body: 'Everything you download lands here, ready to play, share or '
            'grab again.',
        action: FilledButton.tonalIcon(
          onPressed: () => ref.read(tabProvider.notifier).go(AppTab.home),
          icon: const Icon(Icons.add_link_rounded),
          label: const Text('Snag your first video'),
        ),
      );
    } else if (items.isEmpty) {
      body = EmptyState(
        icon: Icons.search_off_rounded,
        title: 'No matches',
        body: _search.text.isEmpty
            ? 'Nothing in this category yet.'
            : 'Nothing matches "${_search.text.trim()}".',
        action: OutlinedButton(
          onPressed: _clearFilters,
          child: const Text('Clear search and filters'),
        ),
      );
    } else {
      body = ListView.builder(
        padding: const EdgeInsets.only(bottom: 32),
        itemCount: items.length,
        itemBuilder: (context, i) => _HistoryRow(item: items[i]),
      );
    }

    return Scaffold(
      appBar: PageHeader(
        title: 'Library',
        actions: [
          if (all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Text(plural(all.length, 'download'),
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
        ],
      ),
      body: ReadableWidth(
        maxWidth: 960,
        child: Column(children: [
          if (all.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Column(children: [
                SearchBar(
                  controller: _search,
                  hintText: 'Search titles, channels, links',
                  leading: const Padding(
                    padding: EdgeInsets.only(left: 8),
                    child: Icon(Icons.search_rounded),
                  ),
                  trailing: [
                    if (_search.text.isNotEmpty)
                      IconButton(
                        tooltip: 'Clear search',
                        onPressed: () => setState(_search.clear),
                        icon: const Icon(Icons.close_rounded),
                      ),
                  ],
                  elevation: const WidgetStatePropertyAll(0),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(spacing: 8, children: [
                    for (final f in _Filter.values)
                      ChoiceChip(
                        label: Text(switch (f) {
                          _Filter.all => 'All',
                          _Filter.video => 'Video',
                          _Filter.audio => 'Audio',
                        }),
                        selected: _filter == f,
                        onSelected: (_) => setState(() => _filter = f),
                      ),
                    if (filtering)
                      ActionChip(
                        avatar: const Icon(Icons.filter_alt_off_rounded),
                        label: const Text('Clear'),
                        onPressed: _clearFilters,
                      ),
                  ]),
                ),
              ]),
            ),
          Expanded(child: body),
        ]),
      ),
    );
  }
}

enum _RowAction { open, reveal, again, copy, remove, delete }

class _HistoryRow extends ConsumerWidget {
  const _HistoryRow({required this.item});
  final HistoryItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final compact = MediaQuery.sizeOf(context).width < 600;
    final isAudio = item.spec.mode == DownloadMode.audio;

    final meta = [
      if (item.meta.uploader != null) item.meta.uploader!,
      if (item.fileSize != null) formatBytes(item.fileSize),
      formatRelative(item.finishedAt),
    ].join(' · ');

    return InkWell(
      onTap: () => LibraryActions.open(context, ref, item),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(children: [
          MediaThumb(
            url: item.meta.thumbnail,
            width: compact ? 104 : 136,
            radius: 14,
            duration: item.meta.duration,
            icon: isAudio ? Icons.music_note_rounded : Icons.movie_outlined,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Tooltip(
                message: item.title,
                child: Text(item.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall),
              ),
              const SizedBox(height: 4),
              Text(meta,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
              const SizedBox(height: 6),
              Row(children: [
                Icon(isAudio ? Icons.music_note_rounded : Icons.movie_rounded,
                    size: 14, color: scheme.primary),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(item.spec.summary,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall
                          ?.copyWith(color: scheme.primary)),
                ),
              ]),
            ]),
          ),
          PopupMenuButton<_RowAction>(
            tooltip: 'More',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (a) => switch (a) {
              _RowAction.open => LibraryActions.open(context, ref, item),
              _RowAction.reveal =>
                PlatformActions.revealInFolder(item.filePath!),
              _RowAction.again => LibraryActions.redownload(context, ref, item),
              _RowAction.copy => LibraryActions.copyLink(context, item),
              _RowAction.remove => LibraryActions.removeEntry(context, ref, item),
              _RowAction.delete => LibraryActions.deleteFile(context, ref, item),
            },
            itemBuilder: (context) => [
              if (item.filePath != null)
                const PopupMenuItem(
                  value: _RowAction.open,
                  child: ListTile(
                      leading: Icon(Icons.play_arrow_rounded),
                      title: Text('Open')),
                ),
              if (item.filePath != null && PlatformActions.canRevealInFolder)
                const PopupMenuItem(
                  value: _RowAction.reveal,
                  child: ListTile(
                      leading: Icon(Icons.folder_open_rounded),
                      title: Text('Show in folder')),
                ),
              const PopupMenuItem(
                value: _RowAction.again,
                child: ListTile(
                    leading: Icon(Icons.replay_rounded),
                    title: Text('Download again')),
              ),
              const PopupMenuItem(
                value: _RowAction.copy,
                child: ListTile(
                    leading: Icon(Icons.link_rounded), title: Text('Copy link')),
              ),
              const PopupMenuDivider(),
              const PopupMenuItem(
                value: _RowAction.remove,
                child: ListTile(
                    leading: Icon(Icons.playlist_remove_rounded),
                    title: Text('Remove from library')),
              ),
              if (item.filePath != null)
                PopupMenuItem(
                  value: _RowAction.delete,
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded,
                        color: scheme.error),
                    title: Text('Delete file',
                        style: TextStyle(color: scheme.error)),
                  ),
                ),
            ],
          ),
        ]),
      ),
    );
  }
}
