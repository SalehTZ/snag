import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../data/providers.dart';
import '../../data/settings.dart';
import '../../engine/binary_manager.dart';
import '../../engine/ytdlp_engine.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/shapes.dart';
import '../setup/components_controller.dart';

/// yt-dlp / ffmpeg / Deno status with install and update actions.
class ComponentsSection extends ConsumerWidget {
  const ComponentsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!isDesktop) {
      return const Column(children: [MobileEngineTile(), NightlySwitch()]);
    }
    final states = ref.watch(componentsProvider);
    final ctrl = ref.read(componentsProvider.notifier);
    final settings = ref.watch(settingsProvider);
    final l = context.l10n;

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
                      dialogTitle: l.componentChooseExecutable(c.label));
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
      const NightlySwitch(),
    ]);
  }
}

class NightlySwitch extends ConsumerWidget {
  const NightlySwitch({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final l = context.l10n;
    return SwitchListTile(
      secondary: const Icon(Icons.science_outlined),
      title: Text(l.settingsNightly),
      subtitle: Text(l.settingsNightlySubtitle),
      value: settings.updateChannel == UpdateChannel.nightly,
      onChanged: (v) => ref.read(settingsProvider.notifier).update((s) =>
          s.copyWith(
              updateChannel: v ? UpdateChannel.nightly : UpdateChannel.stable)),
    );
  }
}

/// Words an update outcome in the current language.
String describeUpdate(AppLocalizations l, UpdateResult r) {
  final version = r.version ?? l.componentUnknownVersion;
  return r.changed ? l.componentUpdated(version) : l.componentUpToDate(version);
}

/// "Downloading 42%" in the current language.
String describeProgress(BuildContext context, ComponentState state) {
  final l = context.l10n;
  final stage = l.installStage(state.stage ?? InstallStage.starting);
  if (state.progress == null) return stage;
  return l.installProgress(stage, context.fmt.percent(state.progress!));
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
    final l = context.l10n;
    final status = state.status;
    final source = status?.source;

    String subtitle;
    if (state.busy) {
      subtitle = describeProgress(context, state);
    } else if (status == null) {
      subtitle = l.componentChecking;
    } else if (!status.available) {
      subtitle = l.componentNotInstalled(l.purpose(component));
    } else {
      subtitle = [
        status.version ?? l.componentUnknownVersion,
        switch (source!) {
          ComponentSource.managed => l.componentManaged(AppInfo.name),
          ComponentSource.system => l.componentFromSystem,
          ComponentSource.custom => l.componentCustom(status.path ?? ''),
          ComponentSource.missing => '',
        },
      ].join(' · ');
    }

    final note = state.update != null
        ? describeUpdate(l, state.update!)
        : state.justInstalled
            ? l.componentInstalled
            : null;

    final actions = <Widget>[
      if (state.busy)
        const Padding(
          padding: EdgeInsets.all(8),
          child: MorphingLoader(size: 24),
        )
      else if (status != null && !status.available)
        FilledButton.tonal(onPressed: onInstall, child: Text(l.componentInstall))
      else if (onUpdate != null && status != null)
        FilledButton.tonal(onPressed: onUpdate, child: Text(l.componentUpdate)),
      if (!state.busy && (onPickCustom != null || onClearCustom != null))
        PopupMenuButton<int>(
          tooltip: l.commonMore,
          onSelected: (v) =>
              v == 0 ? onPickCustom?.call() : onClearCustom?.call(),
          itemBuilder: (_) => [
            if (onPickCustom != null)
              PopupMenuItem(value: 0, child: Text(l.componentUseCustom)),
            if (onClearCustom != null)
              PopupMenuItem(value: 1, child: Text(l.componentStopCustom)),
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
          padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 24, 8),
          // ignore: deprecated_member_use
          child: LinearProgressIndicator(value: state.progress, year2023: false),
        ),
      if (state.error != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ErrorPanel(
            message: l.componentInstallFailed,
            details: state.error,
            onRetry: onInstall,
            compact: true,
          ),
        ),
      if (note != null && !state.busy)
        Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(72, 0, 24, 8),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Text(note,
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
class MobileEngineTile extends ConsumerStatefulWidget {
  const MobileEngineTile({super.key});

  @override
  ConsumerState<MobileEngineTile> createState() => _MobileEngineTileState();
}

class _MobileEngineTileState extends ConsumerState<MobileEngineTile> {
  String? _version;
  bool _loaded = false;
  bool _busy = false;
  UpdateResult? _result;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final v =
          await ref.read(engineProvider).version(ref.read(settingsProvider));
      if (mounted) setState(() => _version = v);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _loaded = true);
    }
  }

  Future<void> _update() async {
    setState(() {
      _busy = true;
      _result = null;
      _error = null;
    });
    try {
      final r =
          await ref.read(engineProvider).update(ref.read(settingsProvider));
      _result = r;
      _version = r.version ?? _version;
    } catch (e) {
      _error = e;
    }
    if (mounted) setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final l = context.l10n;
    final subtitle = _result != null
        ? describeUpdate(l, _result!)
        : !_loaded
            ? l.componentChecking
            : _version ?? l.componentUnavailable;
    return Column(children: [
      ListTile(
        leading: const Icon(Icons.memory_rounded),
        title: const Text('yt-dlp'),
        subtitle: Text(subtitle),
        trailing: _busy
            ? const MorphingLoader(size: 24)
            : FilledButton.tonal(
                onPressed: _update, child: Text(l.componentUpdate)),
      ),
      if (_error != null)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: ErrorPanel(
            message: l.engineError(_error!),
            details: l.errorDetails(_error!),
            onRetry: _update,
            compact: true,
          ),
        ),
    ]);
  }
}
