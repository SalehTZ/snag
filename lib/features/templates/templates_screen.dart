import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/records.dart';
import '../../engine/args_builder.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';

/// Saved sets of raw yt-dlp flags, picked from "More options" in the
/// download sheet.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    final l = context.l10n;
    return Scaffold(
      appBar: PageHeader(title: l.templatesTitle),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: Text(l.templatesNew),
      ),
      body: templates.isEmpty
          ? EmptyState(
              icon: Icons.terminal_rounded,
              title: l.templatesEmptyTitle,
              body: l.templatesEmptyBody,
              action: FilledButton.tonalIcon(
                onPressed: () => _edit(context, ref, null),
                icon: const Icon(Icons.add_rounded),
                label: Text(l.templatesCreate),
              ),
            )
          : ReadableWidth(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 96),
                itemCount: templates.length,
                separatorBuilder: (_, _) => const Divider(indent: 16, endIndent: 16),
                itemBuilder: (context, i) {
                  final t = templates[i];
                  return ListTile(
                    title: Text(t.name),
                    subtitle: Text(t.args,
                        textDirection: TextDirection.ltr,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: monoStyle.copyWith(fontSize: 12)),
                    onTap: () => _edit(context, ref, t),
                    trailing: IconButton(
                      tooltip: l.templatesDelete,
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () {
                        final notifier = ref.read(templatesProvider.notifier);
                        notifier.remove(t.id);
                        showSnack(context, l.templatesDeleted,
                            actionLabel: l.commonUndo,
                            onAction: () => notifier.upsert(t));
                      },
                    ),
                  );
                },
              ),
            ),
    );
  }

  Future<void> _edit(
      BuildContext context, WidgetRef ref, CommandTemplate? existing) async {
    final result = await showDialog<CommandTemplate>(
      context: context,
      builder: (_) => _TemplateDialog(existing: existing),
    );
    if (result != null) ref.read(templatesProvider.notifier).upsert(result);
  }
}

class _TemplateDialog extends StatefulWidget {
  const _TemplateDialog({this.existing});
  final CommandTemplate? existing;

  @override
  State<_TemplateDialog> createState() => _TemplateDialogState();
}

class _TemplateDialogState extends State<_TemplateDialog> {
  late final _name = TextEditingController(text: widget.existing?.name);
  late final _args = TextEditingController(text: widget.existing?.args);
  String? _nameError;
  String? _argsError;

  @override
  void dispose() {
    _name.dispose();
    _args.dispose();
    super.dispose();
  }

  void _save() {
    final name = _name.text.trim();
    final args = _args.text.trim();
    final l = context.l10n;
    setState(() {
      _nameError = name.isEmpty ? l.templatesNameError : null;
      _argsError = args.isEmpty
          ? l.templatesFlagsError
          : ArgsBuilder.splitArgs(args).any((a) => a.startsWith('http'))
              ? l.templatesNoLink
              : null;
    });
    if (_nameError != null || _argsError != null) return;
    Navigator.pop(
      context,
      CommandTemplate(
        id: widget.existing?.id ??
            DateTime.now().microsecondsSinceEpoch.toRadixString(36),
        name: name,
        args: args,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    return AlertDialog(
      title: Text(widget.existing == null ? l.templatesNew : l.templatesEdit),
      content: SizedBox(
        width: 520,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration:
                InputDecoration(labelText: l.templatesName, errorText: _nameError),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _args,
            minLines: 3,
            maxLines: 6,
            textDirection: TextDirection.ltr,
            style: monoStyle.copyWith(fontSize: 13),
            decoration: InputDecoration(
              labelText: l.templatesFlags,
              hintText: '-f "bv*+ba" --merge-output-format mkv',
              errorText: _argsError,
              helperText: l.templatesFlagsHelper,
              helperMaxLines: 2,
              alignLabelWithHint: true,
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: Text(l.commonCancel)),
        FilledButton(onPressed: _save, child: Text(l.templatesSave)),
      ],
    );
  }
}
