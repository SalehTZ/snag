import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../data/providers.dart';
import '../../engine/models.dart';
import '../../shell.dart';
import '../../widgets/common.dart';
import '../library/library_actions.dart';

/// The last few downloads, as rows, so Home is useful on the 100th visit too.
class RecentStrip extends ConsumerWidget {
  const RecentStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recent = ref.watch(historyProvider).take(3).toList();
    if (recent.isEmpty) return const SizedBox.shrink();
    final theme = Theme.of(context);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
          child: Text('Recently snagged',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        TextButton(
          onPressed: () => ref.read(tabProvider.notifier).go(AppTab.library),
          child: const Text('See all'),
        ),
      ]),
      const SizedBox(height: 4),
      for (final item in recent)
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 4),
          leading: MediaThumb(
            url: item.meta.thumbnail,
            width: 88,
            radius: 12,
            icon: item.spec.mode == DownloadMode.audio
                ? Icons.music_note_rounded
                : Icons.movie_outlined,
          ),
          title: Text(item.title, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            [
              if (item.meta.uploader != null) item.meta.uploader!,
              formatRelative(item.finishedAt),
            ].join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          onTap: () => LibraryActions.open(context, ref, item),
        ),
    ]);
  }
}
