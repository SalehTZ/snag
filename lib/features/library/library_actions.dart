import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/platform_actions.dart';
import '../../data/providers.dart';
import '../../data/records.dart';
import '../../l10n/l10n.dart';
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
      showSnack(context, context.l10n.commonFileMissing,
          actionLabel: context.l10n.commonDownloadAgain,
          onAction: () => redownload(context, ref, item));
    }
  }

  static void redownload(BuildContext context, WidgetRef ref, HistoryItem item) {
    final tabs = ref.read(tabProvider.notifier);
    ref.read(downloadManagerProvider.notifier).enqueue(item.spec, item.meta);
    showSnack(context, context.l10n.commonAddedToQueue,
        actionLabel: context.l10n.commonView,
        onAction: () => tabs.go(AppTab.queue));
  }

  static void copyLink(BuildContext context, HistoryItem item) {
    Clipboard.setData(ClipboardData(text: item.spec.url));
    showSnack(context, context.l10n.commonLinkCopied);
  }

  static void removeEntry(BuildContext context, WidgetRef ref, HistoryItem item) {
    final history = ref.read(historyProvider.notifier);
    history.remove(item.id);
    showSnack(context, context.l10n.libraryRemoved,
        actionLabel: context.l10n.commonUndo,
        onAction: () => history.add(item));
  }

  /// Destructive: confirm with focus on the safe action.
  static Future<void> deleteFile(
      BuildContext context, WidgetRef ref, HistoryItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.delete_forever_rounded),
        title: Text(context.l10n.libraryDeleteTitle),
        content: Text(context.l10n.libraryDeleteBody(item.title)),
        actions: [
          FilledButton.tonal(
            autofocus: true,
            onPressed: () => Navigator.pop(context, false),
            child: Text(context.l10n.libraryKeepIt),
          ),
          TextButton(
            style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: Text(context.l10n.libraryDeleteFile),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final f = File(item.filePath!);
      if (await f.exists()) await f.delete();
    } catch (e) {
      if (context.mounted) {
        showSnack(context, context.l10n.libraryDeleteFailed('$e'));
      }
      return;
    }
    ref.read(historyProvider.notifier).remove(item.id);
    if (context.mounted) showSnack(context, context.l10n.libraryDeleted);
  }
}
