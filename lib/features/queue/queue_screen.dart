import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/format.dart';
import '../../core/platform_actions.dart';
import '../../core/theme/motion.dart';
import '../../engine/models.dart';
import '../../shell.dart';
import '../../widgets/common.dart';
import 'download_manager.dart';

class QueueScreen extends ConsumerWidget {
  const QueueScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(downloadManagerProvider);
    final manager = ref.read(downloadManagerProvider.notifier);
    final active = tasks
        .where((t) =>
            t.status == TaskStatus.running ||
            t.status == TaskStatus.processing)
        .toList();
    final waiting = tasks.where((t) => t.status == TaskStatus.queued).toList();
    final finished = tasks.where((t) => t.isFinished).toList().reversed.toList();
    final failed = finished.where((t) => t.status == TaskStatus.failed).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Queue'),
        actions: [
          if (failed > 0)
            TextButton.icon(
              onPressed: manager.retryAllFailed,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(failed == 1 ? 'Retry failed' : 'Retry $failed failed'),
            ),
          if (finished.isNotEmpty)
            TextButton.icon(
              onPressed: manager.clearFinished,
              icon: const Icon(Icons.done_all_rounded),
              label: const Text('Clear finished'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: tasks.isEmpty
          ? EmptyState(
              icon: Icons.downloading_rounded,
              title: 'All caught up',
              body: 'Nothing is downloading right now. Paste a link on the '
                  'Snag tab and it will show up here.',
              action: FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(tabProvider.notifier).go(AppTab.home),
                icon: const Icon(Icons.add_link_rounded),
                label: const Text('Paste a link'),
              ),
            )
          : ReadableWidth(
              maxWidth: 960,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  if (active.isNotEmpty) ...[
                    SectionHeader('Downloading (${active.length})'),
                    for (final t in active) TaskRow(task: t),
                  ],
                  if (waiting.isNotEmpty) ...[
                    SectionHeader('Waiting (${waiting.length})'),
                    for (final t in waiting) TaskRow(task: t),
                  ],
                  if (finished.isNotEmpty) ...[
                    SectionHeader('Finished (${finished.length})'),
                    for (final t in finished) TaskRow(task: t),
                  ],
                ],
              ),
            ),
    );
  }
}

class TaskRow extends ConsumerWidget {
  const TaskRow({super.key, required this.task});
  final DownloadTask task;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final manager = ref.read(downloadManagerProvider.notifier);
    final compact = MediaQuery.sizeOf(context).width < 600;

    final statusColor = switch (task.status) {
      TaskStatus.failed => scheme.error,
      TaskStatus.completed => scheme.primary,
      _ => scheme.onSurfaceVariant,
    };

    return InkWell(
      onTap: () => _showDetails(context, ref),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          MediaThumb(
            url: task.meta.thumbnail,
            width: compact ? 104 : 136,
            radius: 14,
            duration: task.meta.duration,
            icon: task.spec.mode == DownloadMode.audio
                ? Icons.music_note_rounded
                : Icons.movie_outlined,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(task.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                _statusLine(task),
                maxLines: task.status == TaskStatus.failed ? 3 : 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: statusColor,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              if (task.isActive) ...[
                const SizedBox(height: 10),
                _Progress(task: task),
              ],
            ]),
          ),
          const SizedBox(width: 8),
          ..._actions(context, manager),
        ]),
      ),
    );
  }

  List<Widget> _actions(BuildContext context, DownloadManager manager) {
    switch (task.status) {
      case TaskStatus.queued:
      case TaskStatus.running:
      case TaskStatus.processing:
        return [
          IconButton(
            tooltip: 'Cancel',
            onPressed: () => manager.cancel(task.id),
            icon: const Icon(Icons.close_rounded),
          ),
        ];
      case TaskStatus.completed:
        return [
          if (task.filePath != null)
            IconButton.filledTonal(
              tooltip: 'Open',
              onPressed: () => _open(context),
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          IconButton(
            tooltip: 'Remove from queue',
            onPressed: () => manager.remove(task.id),
            icon: const Icon(Icons.close_rounded),
          ),
        ];
      case TaskStatus.failed:
      case TaskStatus.cancelled:
        return [
          IconButton.filledTonal(
            tooltip: 'Retry',
            onPressed: () => manager.retry(task.id),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Remove from queue',
            onPressed: () => manager.remove(task.id),
            icon: const Icon(Icons.close_rounded),
          ),
        ];
    }
  }

  Future<void> _open(BuildContext context) async {
    final ok = await PlatformActions.openFile(task.filePath!);
    if (!ok && context.mounted) {
      showSnack(context, 'The file was moved or deleted.');
    }
  }

  static String _statusLine(DownloadTask t) {
    switch (t.status) {
      case TaskStatus.queued:
        return 'Waiting · ${t.spec.summary}';
      case TaskStatus.processing:
        return t.stage ?? 'Processing';
      case TaskStatus.running:
        final p = t.progress;
        if (p == null) return 'Starting · ${t.spec.summary}';
        final parts = <String>[
          if (p.fraction != null) '${(p.fraction! * 100).toStringAsFixed(0)}%',
          if (p.total != null)
            '${formatBytes(p.downloaded)} of ${formatBytes(p.total)}'
          else if (p.downloaded != null)
            formatBytes(p.downloaded),
          if (p.speed != null) formatSpeed(p.speed),
          if (p.eta != null) '${formatEta(p.eta)} left',
        ];
        return parts.join(' · ');
      case TaskStatus.completed:
        return t.filePath == null
            ? 'Done'
            : 'Saved · ${t.spec.summary}';
      case TaskStatus.failed:
        return t.error ?? 'Failed';
      case TaskStatus.cancelled:
        return 'Cancelled';
    }
  }

  void _showDetails(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _TaskDetails(taskId: task.id),
    );
  }
}

class _Progress extends StatelessWidget {
  const _Progress({required this.task});
  final DownloadTask task;

  @override
  Widget build(BuildContext context) {
    if (task.status == TaskStatus.queued) {
      // ignore: deprecated_member_use
      return const LinearProgressIndicator(value: 0, year2023: false);
    }
    final value =
        task.status == TaskStatus.running ? task.progress?.fraction : null;
    if (value == null) {
      // ignore: deprecated_member_use
      return const LinearProgressIndicator(year2023: false);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value),
      duration: Motion.of(context, Motion.short),
      curve: Motion.effects,
      builder: (context, v, _) =>
          // ignore: deprecated_member_use
          LinearProgressIndicator(value: v, year2023: false),
    );
  }
}

class _TaskDetails extends ConsumerWidget {
  const _TaskDetails({required this.taskId});
  final String taskId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final task = ref
        .watch(downloadManagerProvider)
        .where((t) => t.id == taskId)
        .firstOrNull;
    if (task == null) return const SizedBox(height: 120);
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          SelectableText(task.title, style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          SelectableText(task.spec.url,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (task.status == TaskStatus.failed)
            ErrorPanel(
              message: task.error ?? 'Failed',
              details: task.errorDetails,
              onRetry: () {
                ref.read(downloadManagerProvider.notifier).retry(task.id);
                Navigator.pop(context);
              },
            ),
          if (task.filePath != null) ...[
            Text('Saved to', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            SelectableText(task.filePath!),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilledButton.tonalIcon(
                onPressed: () => PlatformActions.openFile(task.filePath!),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Open'),
              ),
              if (PlatformActions.canRevealInFolder)
                OutlinedButton.icon(
                  onPressed: () => PlatformActions.revealInFolder(task.filePath!),
                  icon: const Icon(Icons.folder_open_rounded),
                  label: const Text('Show in folder'),
                ),
            ]),
          ],
          const SizedBox(height: 20),
          Text('Log', style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              task.log.isEmpty ? 'No output yet.' : task.log.join('\n'),
              style: const TextStyle(
                  fontFamily: 'monospace', fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
