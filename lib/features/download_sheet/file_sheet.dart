import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../engine/file_probe.dart';
import '../../engine/models.dart';
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

class FileSheet extends ConsumerWidget {
  const FileSheet({super.key, required this.file, this.inDialog = false});

  final RemoteFile file;
  final bool inDialog;

  void _download(BuildContext context, WidgetRef ref) {
    ref.read(downloadManagerProvider.notifier).enqueue(
          DownloadSpec(url: file.url, kind: DownloadKind.file),
          MediaMeta(title: file.name, uploader: file.host),
        );
    // Same hand-off as the media sheet: the root messenger outlives this route.
    final tabs = ref.read(tabProvider.notifier);
    final l = context.l10n;
    showSnack(context, l.commonAddedToQueue,
        actionLabel: l.commonView, onAction: () => tabs.go(AppTab.queue));
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final meta = [
      if (file.size != null) context.fmt.bytes(file.size),
      if (file.host.isNotEmpty) file.host,
    ].join(' · ');

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(24, inDialog ? 24 : 0, 24, inDialog ? 24 : 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isTorrent(file.url) ? l.summaryTorrent : l.summaryFile,
                style: theme.textTheme.labelMedium
                    ?.copyWith(color: scheme.primary, letterSpacing: 1.2)),
            const SizedBox(height: 6),
            // Primary content: wraps, never truncates.
            SizedBox(
              width: double.infinity,
              child: SelectableText(file.name,
                  textDirection: contentDirection(file.name),
                  style: theme.textTheme.titleLarge),
            ),
            if (meta.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(meta,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  )),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 60,
              child: FilledButton.icon(
                onPressed: () => _download(context, ref),
                icon: const Icon(Icons.download_rounded),
                label: Text(l.sheetDownloadFile),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
