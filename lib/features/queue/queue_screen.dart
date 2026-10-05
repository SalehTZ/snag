import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../l10n/l10n.dart';
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
    final compact = MediaQuery.sizeOf(context).width < 600;
    final l = context.l10n;

    return Scaffold(
      appBar: PageHeader(
        title: l.queueTitle,
        actions: [
          if (failed > 0)
            compact
                ? IconButton(
                    tooltip: l.queueRetryFailed(failed),
                    onPressed: manager.retryAllFailed,
                    icon: const Icon(Icons.refresh_rounded),
                  )
                : TextButton.icon(
                    onPressed: manager.retryAllFailed,
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l.queueRetryFailed(failed)),
                  ),
          if (finished.isNotEmpty)
            compact
                ? IconButton(
                    tooltip: l.queueClearFinished,
                    onPressed: manager.clearFinished,
                    icon: const Icon(Icons.done_all_rounded),
                  )
                : TextButton.icon(
                    onPressed: manager.clearFinished,
                    icon: const Icon(Icons.done_all_rounded),
                    label: Text(l.queueClearFinished),
                  ),
        ],
      ),
      body: tasks.isEmpty
          ? EmptyState(
              icon: Icons.downloading_rounded,
              title: l.queueEmptyTitle,
              body: l.queueEmptyBody,
              action: FilledButton.tonalIcon(
                onPressed: () =>
                    ref.read(tabProvider.notifier).go(AppTab.home),
                icon: const Icon(Icons.add_link_rounded),
                label: Text(l.queuePasteLink),
              ),
            )
          : ReadableWidth(
              maxWidth: 960,
              child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: [
                  if (active.isNotEmpty) ...[
                    SectionHeader(l.queueDownloading(active.length)),
                    for (final t in active) TaskRow(task: t),
                  ],
                  if (waiting.isNotEmpty) ...[
                    SectionHeader(l.queueWaiting(waiting.length)),
                    for (final t in waiting) TaskRow(task: t),
                  ],
                  if (finished.isNotEmpty) ...[
                    SectionHeader(l.queueFinished(finished.length)),
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
              SizedBox(
                width: double.infinity,
                child: Text(task.title,
                    textDirection: contentDirection(task.title),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleSmall),
              ),
              const SizedBox(height: 4),
              Text(
                _statusLine(context, task),
                maxLines: task.status == TaskStatus.failed ? 3 : 2,
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
          ..._actions(context, manager, context.l10n),
        ]),
      ),
    );
  }

  List<Widget> _actions(
      BuildContext context, DownloadManager manager, AppLocalizations l) {
    switch (task.status) {
      case TaskStatus.queued:
      case TaskStatus.running:
      case TaskStatus.processing:
        return [
          IconButton(
            tooltip: l.commonCancel,
            onPressed: () => manager.cancel(task.id),
            icon: const Icon(Icons.close_rounded),
          ),
        ];
      case TaskStatus.completed:
        return [
          if (task.filePath != null)
            IconButton.filledTonal(
              tooltip: l.commonOpen,
              onPressed: () => _open(context),
              icon: const Icon(Icons.play_arrow_rounded),
            ),
          IconButton(
            tooltip: l.queueRemove,
            onPressed: () => manager.remove(task.id),
            icon: const Icon(Icons.close_rounded),
          ),
        ];
      case TaskStatus.failed:
      case TaskStatus.cancelled:
        return [
          IconButton.filledTonal(
            tooltip: l.commonRetry,
            onPressed: () => manager.retry(task.id),
            icon: const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: l.queueRemove,
            onPressed: () => manager.remove(task.id),
            icon: const Icon(Icons.close_rounded),
          ),
        ];
    }
  }

  Future<void> _open(BuildContext context) async {
    final ok = await PlatformActions.openFile(task.filePath!);
    if (!ok && context.mounted) {
      showSnack(context, context.l10n.commonFileMissing);
    }
  }

  static String _statusLine(BuildContext context, DownloadTask t) {
    final l = context.l10n;
    final fmt = context.fmt;
    switch (t.status) {
      case TaskStatus.queued:
        return l.statusWaiting(l.summary(t.spec));
      case TaskStatus.processing:
        return l.stage(t.stage);
      case TaskStatus.running:
        final p = t.progress;
        if (p == null) return l.statusStarting(l.summary(t.spec));
        final parts = <String>[
          if (p.fraction != null) fmt.percent(p.fraction!),
          if (p.total != null)
            l.progressOf(fmt.bytes(p.downloaded), fmt.bytes(p.total))
          else if (p.downloaded != null)
            fmt.bytes(p.downloaded),
          if (p.speed != null) fmt.speed(p.speed),
          if (p.eta != null) l.timeLeft(fmt.eta(p.eta)),
        ];
        return parts.join(' · ');
      case TaskStatus.completed:
        return t.filePath == null
            ? l.statusDone
            : l.statusSaved(l.summary(t.spec));
      case TaskStatus.failed:
        return t.failure == null ? l.statusFailed : l.engineError(t.failure!);
      case TaskStatus.cancelled:
        return l.statusCancelled;
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
    final l = context.l10n;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.95,
      builder: (context, scroll) => ListView(
        controller: scroll,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          SelectableText(task.title,
              textDirection: contentDirection(task.title),
              style: theme.textTheme.titleLarge),
          const SizedBox(height: 4),
          SelectableText(task.spec.url,
              textDirection: TextDirection.ltr,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          if (task.status == TaskStatus.failed)
            ErrorPanel(
              message: task.failure == null
                  ? l.statusFailed
                  : l.engineError(task.failure!),
              details: task.failure == null
                  ? task.log.join('\n')
                  : l.errorDetails(task.failure!),
              onRetry: () {
                ref.read(downloadManagerProvider.notifier).retry(task.id);
                Navigator.pop(context);
              },
            ),
          if (task.filePath != null) ...[
            Text(l.queueSavedTo, style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            SelectableText(task.filePath!, textDirection: TextDirection.ltr),
            const SizedBox(height: 8),
            Wrap(spacing: 8, children: [
              FilledButton.tonalIcon(
                onPressed: () => PlatformActions.openFile(task.filePath!),
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l.commonOpen),
              ),
              if (PlatformActions.canRevealInFolder)
                OutlinedButton.icon(
                  onPressed: () => PlatformActions.revealInFolder(task.filePath!),
                  icon: const Icon(Icons.folder_open_rounded),
                  label: Text(l.commonShowInFolder),
                ),
            ]),
          ],
          const SizedBox(height: 20),
          Text(l.queueLog, style: theme.textTheme.titleSmall),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SelectableText(
              task.log.isEmpty ? l.queueNoOutput : task.log.join('\n'),
              textDirection:
                  task.log.isEmpty ? null : TextDirection.ltr,
              style: monoStyle.copyWith(fontSize: 12, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
