import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/theme.dart';
import '../../data/providers.dart';
import '../../engine/binary_manager.dart';
import '../../widgets/shapes.dart';
import 'components_controller.dart';

/// First run on desktop: get yt-dlp (and friends) in place with one click.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _wanted = {Component.ytDlp, Component.ffmpeg, Component.deno};
  bool _running = false;

  Future<void> _install() async {
    setState(() => _running = true);
    final ctrl = ref.read(componentsProvider.notifier);
    final states = ref.read(componentsProvider);
    for (final c in Component.values) {
      if (!_wanted.contains(c)) continue;
      if (states[c]?.available ?? false) continue;
      final ok = await ctrl.install(c);
      // yt-dlp is the only hard requirement; keep going for the others.
      if (!ok && c == Component.ytDlp) break;
    }
    if (mounted) setState(() => _running = false);
  }

  void _finish() =>
      ref.read(settingsProvider.notifier).update((s) => s.copyWith(setupDone: true));

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final states = ref.watch(componentsProvider);
    final ytReady = states[Component.ytDlp]?.available ?? false;
    final missing = _wanted.where((c) => !(states[c]?.available ?? false));
    final loaded = states.values.every((s) => s.status != null);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ShapeIcon(
                    icon: Icons.south_rounded,
                    size: 96,
                    color: scheme.primary,
                    iconColor: scheme.onPrimary,
                  ),
                  const SizedBox(height: 32),
                  Text('Welcome to ${AppInfo.name}',
                      style: theme.textTheme.displaySmall),
                  const SizedBox(height: 12),
                  Text(
                    '${AppInfo.name} runs on yt-dlp, the open source engine '
                    'behind most good downloaders. Let\'s fetch the pieces it '
                    'needs. They live inside ${AppInfo.name}\'s own folder '
                    'and nothing is installed system-wide.',
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  for (final c in Component.values)
                    _ComponentTile(
                      component: c,
                      state: states[c] ?? const ComponentState(),
                      wanted: _wanted.contains(c),
                      locked: c == Component.ytDlp || _running,
                      onToggle: (v) => setState(
                          () => v ? _wanted.add(c) : _wanted.remove(c)),
                    ),
                  const SizedBox(height: 28),
                  if (!loaded)
                    const Center(child: MorphingLoader())
                  else if (missing.isEmpty && !_running)
                    SizedBox(
                      width: double.infinity,
                      height: 60,
                      child: FilledButton.icon(
                        onPressed: _finish,
                        icon: const Icon(Icons.arrow_forward_rounded),
                        label: const Text('Start snagging'),
                      ),
                    )
                  else
                    Column(children: [
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: FilledButton.icon(
                          onPressed: _running ? null : _install,
                          icon: _running
                              ? MorphingLoader(size: 22, color: scheme.onPrimary)
                              : const Icon(Icons.download_rounded),
                          label: Text(_running
                              ? 'Setting things up...'
                              : 'Get everything ready'),
                        ),
                      ),
                      if (ytReady && !_running) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: _finish,
                          child: const Text('Skip the optional parts'),
                        ),
                      ],
                    ]),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ComponentTile extends StatelessWidget {
  const _ComponentTile({
    required this.component,
    required this.state,
    required this.wanted,
    required this.locked,
    required this.onToggle,
  });

  final Component component;
  final ComponentState state;
  final bool wanted;
  final bool locked;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final status = state.status;

    String subtitle;
    if (state.error != null) {
      subtitle = 'Failed: ${state.error}';
    } else if (state.busy) {
      final pct = state.progress == null
          ? ''
          : ' ${(state.progress! * 100).toStringAsFixed(0)}%';
      subtitle = '${state.stage ?? 'Working'}$pct';
    } else if (status == null) {
      subtitle = 'Checking...';
    } else if (status.available) {
      final where = switch (status.source) {
        ComponentSource.managed => 'installed by ${AppInfo.name}',
        ComponentSource.system => 'found on your system',
        ComponentSource.custom => 'custom path',
        ComponentSource.missing => '',
      };
      subtitle = [if (status.version != null) status.version!, where].join(' · ');
    } else {
      subtitle = component.purpose;
    }

    final ready = status?.available ?? false;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd + 4),
      ),
      child: Column(children: [
        ListTile(
          contentPadding: const EdgeInsets.fromLTRB(20, 6, 12, 6),
          leading: AnimatedSwitcher(
            duration: Motion.of(context, Motion.short),
            child: ready
                ? Icon(Icons.check_circle_rounded,
                    key: const ValueKey('ok'), color: scheme.primary)
                : state.busy
                    ? const SizedBox.square(
                        key: ValueKey('busy'),
                        dimension: 24,
                        child: MorphingLoader(size: 24))
                    : Icon(Icons.radio_button_unchecked_rounded,
                        key: const ValueKey('todo'),
                        color: scheme.onSurfaceVariant),
          ),
          title: Text(component.label +
              (component == Component.ytDlp ? '' : '  (recommended)')),
          subtitle: Text(subtitle,
              style: state.error != null
                  ? TextStyle(color: scheme.error)
                  : null),
          trailing: ready || component == Component.ytDlp
              ? null
              : Switch(value: wanted, onChanged: locked ? null : onToggle),
        ),
        if (state.busy)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            // ignore: deprecated_member_use
            child: LinearProgressIndicator(value: state.progress, year2023: false),
          ),
      ]),
    );
  }
}
