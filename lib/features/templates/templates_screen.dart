import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../data/records.dart';
import '../../engine/args_builder.dart';
import '../../widgets/common.dart';

/// Saved sets of raw yt-dlp flags, picked from "More options" in the
/// download sheet.
class TemplatesScreen extends ConsumerWidget {
  const TemplatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templates = ref.watch(templatesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Command templates')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, ref, null),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New template'),
      ),
      body: templates.isEmpty
          ? EmptyState(
              icon: Icons.terminal_rounded,
              title: 'No templates yet',
              body: 'Save any yt-dlp flags you use often, then pick them from '
                  '"More options" when downloading.',
              action: FilledButton.tonalIcon(
                onPressed: () => _edit(context, ref, null),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Create one'),
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
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                    onTap: () => _edit(context, ref, t),
                    trailing: IconButton(
                      tooltip: 'Delete template',
                      icon: const Icon(Icons.delete_outline_rounded),
                      onPressed: () {
                        final notifier = ref.read(templatesProvider.notifier);
                        notifier.remove(t.id);
                        showSnack(context, 'Template deleted',
                            actionLabel: 'Undo',
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
    setState(() {
      _nameError = name.isEmpty ? 'Give it a name you will recognize' : null;
      _argsError = args.isEmpty
          ? 'Add at least one yt-dlp flag'
          : ArgsBuilder.splitArgs(args).any((a) => a.startsWith('http'))
              ? 'Leave the link out; it is added for you'
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
    return AlertDialog(
      title: Text(widget.existing == null ? 'New template' : 'Edit template'),
      content: SizedBox(
        width: 520,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: 'Name', errorText: _nameError),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _args,
            minLines: 3,
            maxLines: 6,
            style: const TextStyle(fontFamily: 'monospace', fontSize: 13),
            decoration: InputDecoration(
              labelText: 'yt-dlp flags',
              hintText: '-f "bv*+ba" --merge-output-format mkv',
              errorText: _argsError,
              helperText: 'Output folder, progress and the link are added automatically.',
              helperMaxLines: 2,
              alignLabelWithHint: true,
            ),
          ),
        ]),
      ),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(onPressed: _save, child: const Text('Save template')),
      ],
    );
  }
}
