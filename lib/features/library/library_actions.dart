import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_actions.dart';
import '../../data/providers.dart';
import '../../data/records.dart';
import '../../shell.dart';
import '../../widgets/common.dart';
import '../queue/download_manager.dart';

/// Row actions shared by the Library and the Home "recent" strip.
abstract final class LibraryActions {
  static Future<void> open(
      BuildContext context, WidgetRef ref, HistoryItem item) async {
    final path = item.filePath;
    final ok = path != null && await PlatformActions.openFile(path);
    if (!ok && context.mounted) {
      showSnack(context, 'The file was moved or deleted.',
          actionLabel: 'Download again',
          onAction: () => redownload(context, ref, item));
    }
  }

  static void redownload(BuildContext context, WidgetRef ref, HistoryItem item) {
    final tabs = ref.read(tabProvider.notifier);
    ref.read(downloadManagerProvider.notifier).enqueue(item.spec, item.meta);
    showSnack(context, 'Added to the queue',
        actionLabel: 'View', onAction: () => tabs.go(AppTab.queue));
  }

  static void copyLink(BuildContext context, HistoryItem item) {
    Clipboard.setData(ClipboardData(text: item.spec.url));
    showSnack(context, 'Link copied');
  }

  static void removeEntry(BuildContext context, WidgetRef ref, HistoryItem item) {
    final history = ref.read(historyProvider.notifier);
    history.remove(item.id);
    showSnack(context, 'Removed from the library. The file is still on disk.',
        actionLabel: 'Undo', onAction: () => history.add(item));
  }

  /// Destructive: confirm with focus on the safe action.
  static Future<void> deleteFile(
      BuildContext context, WidgetRef ref, HistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded),
        title: const Text('Delete this file?'),
        content: Text(
          '"${item.title}" will be removed from your device. This cannot be undone.',
        ),
        actions: [
          FilledButton.tonal(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep it'),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete file'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final f = File(item.filePath!);
      if (await f.exists()) await f.delete();
    } catch (e) {
      if (context.mounted) showSnack(context, 'Could not delete the file: $e');
      return;
    }
    ref.read(historyProvider.notifier).remove(item.id);
    if (context.mounted) showSnack(context, 'File deleted');
  }
}
