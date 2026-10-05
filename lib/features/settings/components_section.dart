import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../data/providers.dart';
import '../../data/settings.dart';
import '../../engine/binary_manager.dart';
import '../../widgets/common.dart';
import '../../widgets/shapes.dart';
import '../setup/components_controller.dart';

/// yt-dlp / ffmpeg / Deno status with install and update actions.
class ComponentsSection extends ConsumerWidget {
  const ComponentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktop) return const _MobileEngineTile();
    final states = ref.watch(componentsProvider);
    final ctrl = ref.read(componentsProvider.notifier);
    final settings = ref.watch(settingsProvider);

    return Column(children: [
      for (final c in Component.values)
        _ComponentRow(
          component: c,
          state: states[c] ?? const ComponentState(),
          onInstall: () => ctrl.install(c),
          onUpdate: c == Component.ytDlp ? ctrl.updateYtDlp : null,
          onPickCustom: c == Component.deno
              ? null
              : () async {
                  final file = await FilePicker.pickFile(
                      dialogTitle: 'Choose the ${c.label} executable');
                  final path = file?.path;
                  if (path == null) return;
                  ref.read(settingsProvider.notifier).update((s) =>
                      c == Component.ytDlp
                          ? s.copyWith(ytDlpPath: () => path)
                          : s.copyWith(ffmpegPath: () => path));
                  await ctrl.refresh();
                },
          onClearCustom: switch (c) {
            Component.ytDlp when settings.ytDlpPath != null => () async {
                ref
                    .read(settingsProvider.notifier)
                    .update((s) => s.copyWith(ytDlpPath: () => null));
                await ctrl.refresh();
              },
            Component.ffmpeg when settings.ffmpegPath != null => () async {
                ref
                    .read(settingsProvider.notifier)
                    .update((s) => s.copyWith(ffmpegPath: () => null));
                await ctrl.refresh();
              },
            _ => null,
          },
        ),
      SwitchListTile(
        secondary: const Icon(Icons.science_outlined),
        title: const Text('Nightly yt-dlp'),
        subtitle: const Text('Fixes for broken sites land here first'),
        value: settings.updateChannel == UpdateChannel.nightly,
        onChanged: (v) => ref.read(settingsProvider.notifier).update((s) =>
            s.copyWith(
                updateChannel: v ? UpdateChannel.nightly : UpdateChannel.stable)),
      ),
    ]);
  }
}

class _ComponentRow extends StatelessWidget {
  const _ComponentRow({
    required this.component,
    required this.state,
    required this.onInstall,
    this.onUpdate,
    this.onPickCustom,
    this.onClearCustom,
  });

  final Component component;
  final ComponentState state;
  final VoidCallback onInstall;
  final VoidCallback? onUpdate;
  final VoidCallback? onPickCustom;
  final VoidCallback? onClearCustom;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final status = state.status;
    final source = status?.source;

    String subtitle;
    if (state.busy) {
      final pct = state.progress == null
          ? ''
          : ' ${(state.progress! * 100).toStringAsFixed(0)}%';
      subtitle = '${state.stage ?? 'Working'}$pct';
    } else if (status == null) {
      subtitle = 'Checking...';
    } else if (!status.available) {
      subtitle = 'Not installed · ${component.purpose}';
    } else {
      subtitle = [
        status.version ?? 'unknown version',
        switch (source!) {
          ComponentSource.managed => 'managed by ${AppInfo.name}',
          ComponentSource.system => 'from your system',
          ComponentSource.custom => 'custom: ${status.path}',
          ComponentSource.missing => '',
        },
      ].join(' · ');
    }

    final actions = <Widget>[
      if (state.busy)
        const Padding(
          padding: EdgeInsets.all(8),
          child: MorphingLoader(size: 24),
        )
      else if (status != null && !status.available)
        FilledButton.tonal(onPressed: onInstall, child: const Text('Install'))
      else if (onUpdate != null && status != null)
        FilledButton.tonal(onPressed: onUpdate, child: const Text('Update')),
      if (!state.busy && (onPickCustom != null || onClearCustom != null))
        PopupMenuButton<int>(
          tooltip: 'More',
          onSelected: (v) => v == 0 ? onPickCustom?.call() : onClearCustom?.call(),
          itemBuilder: (_) => [
            if (onPickCustom != null)
              const PopupMenuItem(value: 0, child: Text('Use a custom executable...')),
            if (onClearCustom != null)
              const PopupMenuItem(value: 1, child: Text('Stop using the custom path')),
          ],
        ),
    ];

    return Column(children: [
      ListTile(
        leading: Icon(
          status?.available ?? false
              ? Icons.check_circle_outline_rounded
              : Icons.error_outline_rounded,
          color: status?.available ?? true ? scheme.primary : scheme.error,
        ),
        title: Text(component.label),
        subtitle: Text(subtitle),
        trailing: Row(mainAxisSize: MainAxisSize.min, children: actions),
      ),
      if (state.busy)
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 24, 8),
          // ignore: deprecated_member_use
          child: LinearProgressIndicator(value: state.progress, year2023: false),
        ),
      if (state.error != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ErrorPanel(
            message: 'Could not finish: check your connection and try again.',
            details: state.error,
            onRetry: onInstall,
            compact: true,
          ),
        ),
      if (state.message != null && !state.busy)
        Padding(
          padding: const EdgeInsets.fromLTRB(72, 0, 24, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(state.message!,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: scheme.primary)),
          ),
        ),
    ]);
  }
}

/// Android: yt-dlp is bundled; only version + update apply.
class _MobileEngineTile extends ConsumerStatefulWidget {
  const _MobileEngineTile();

  @override
  ConsumerState<_MobileEngineTile> createState() => _MobileEngineTileState();
}

class _MobileEngineTileState extends ConsumerState<_MobileEngineTile> {
  String? _version;
  bool _busy = false;
  String? _message;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v = await ref.read(engineProvider).version(ref.read(settingsProvider));
      if (mounted) setState(() => _version = v);
    } catch (e) {
      if (mounted) setState(() => _version = 'unavailable');
    }
  }

  Future<void> _update() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    try {
      final r = await ref.read(engineProvider).update(ref.read(settingsProvider));
      _message = r;
      await _load();
    } catch (e) {
      _message = 'Update failed: $e';
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return Column(children: [
      ListTile(
        leading: const Icon(Icons.memory_rounded),
        title: const Text('yt-dlp'),
        subtitle: Text(_message ?? _version ?? 'Checking...'),
        trailing: _busy
            ? const MorphingLoader(size: 24)
            : FilledButton.tonal(onPressed: _update, child: const Text('Update')),
      ),
      SwitchListTile(
        secondary: const Icon(Icons.science_outlined),
        title: const Text('Nightly yt-dlp'),
        subtitle: const Text('Fixes for broken sites land here first'),
        value: settings.updateChannel == UpdateChannel.nightly,
        onChanged: (v) => ref.read(settingsProvider.notifier).update((s) =>
            s.copyWith(
                updateChannel: v ? UpdateChannel.nightly : UpdateChannel.stable)),
      ),
    ]);
  }
}
