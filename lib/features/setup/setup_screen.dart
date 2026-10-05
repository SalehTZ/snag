import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/platform_actions.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/theme.dart';
import '../../data/providers.dart';
import '../../engine/binary_manager.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/shapes.dart';
import '../settings/components_section.dart';
import '../settings/settings_screen.dart';
import 'components_controller.dart';

/// First run. Desktop fetches yt-dlp and friends; Android has them built in
/// but offers to update the bundled engine and to show progress notifications.
class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    final settings = ref.watch(settingsProvider);

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    ShapeIcon(
                      icon: Icons.south_rounded,
                      size: 88,
                      color: scheme.primary,
                      iconColor: scheme.onPrimary,
                    ),
                    const Spacer(),
                    // Switch language before reading anything else.
                    LanguageButton(
                      current: settings.localeCode,
                      onChanged: (code) => ref
                          .read(settingsProvider.notifier)
                          .update((s) => s.copyWith(localeCode: () => code)),
                    ),
                  ]),
                  const SizedBox(height: 28),
                  Text(l.setupWelcome(AppInfo.name),
                      style: theme.textTheme.displaySmall),
                  const SizedBox(height: 12),
                  Text(
                    isDesktop
                        ? l.setupBodyDesktop(AppInfo.name)
                        : l.setupBodyAndroid(AppInfo.name),
                    style: theme.textTheme.bodyLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 28),
                  if (isDesktop) const _DesktopSetup() else const _MobileSetup(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

void _finish(WidgetRef ref) => ref
    .read(settingsProvider.notifier)
    .update((s) => s.copyWith(setupDone: true));

/// A rounded card row used for each setup step.
class _StepCard extends StatelessWidget {
  const _StepCard({
    required this.leading,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.progress,
    this.busy = false,
    this.error = false,
  });

  final Widget leading;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final double? progress;
  final bool busy;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd + 4),
      ),
      child: Column(children: [
        ListTile(
          contentPadding: const EdgeInsetsDirectional.fromSTEB(20, 6, 12, 6),
          leading: AnimatedSwitcher(
            duration: Motion.of(context, Motion.short),
            child: leading,
          ),
          title: Text(title),
          subtitle: Text(subtitle,
              style: error ? TextStyle(color: scheme.error) : null),
          trailing: trailing,
        ),
        if (busy)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            // ignore: deprecated_member_use
            child: LinearProgressIndicator(value: progress, year2023: false),
          ),
      ]),
    );
  }
}

Widget _doneIcon(ColorScheme scheme) => Icon(Icons.check_circle_rounded,
    key: const ValueKey('ok'), color: scheme.primary);

Widget _todoIcon(ColorScheme scheme) => Icon(
    Icons.radio_button_unchecked_rounded,
    key: const ValueKey('todo'),
    color: scheme.onSurfaceVariant);

const _busyIcon = SizedBox.square(
    key: ValueKey('busy'), dimension: 24, child: MorphingLoader(size: 24));

Widget _primaryButton({
  required VoidCallback? onPressed,
  required Widget icon,
  required String label,
}) =>
    SizedBox(
      width: double.infinity,
      height: 60,
      child: FilledButton.icon(
          onPressed: onPressed, icon: icon, label: Text(label)),
    );

// ------------------------------------------------------------------ desktop

/// yt-dlp from a distro package is usually months old and sites break fast,
/// so setup only counts it as ready when Snag manages (and can update) it.
bool _isReady(Component c, ComponentState? s) {
  final status = s?.status;
  if (status == null || !status.available) return false;
  if (c == Component.ytDlp) return status.source != ComponentSource.system;
  return true;
}

class _DesktopSetup extends ConsumerStatefulWidget {
  const _DesktopSetup();

  @override
  ConsumerState<_DesktopSetup> createState() => _DesktopSetupState();
}

class _DesktopSetupState extends ConsumerState<_DesktopSetup> {
  final _wanted = {Component.ytDlp, Component.ffmpeg, Component.deno};
  bool _running = false;

  Future<void> _install() async {
    setState(() => _running = true);
    final ctrl = ref.read(componentsProvider.notifier);
    for (final c in Component.values) {
      if (!_wanted.contains(c)) continue;
      if (_isReady(c, ref.read(componentsProvider)[c])) continue;
      final ok = await ctrl.install(c);
      // yt-dlp is the only hard requirement; keep going for the others.
      if (!ok && c == Component.ytDlp) break;
    }
    if (mounted) setState(() => _running = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final states = ref.watch(componentsProvider);
    final ytAvailable = states[Component.ytDlp]?.available ?? false;
    final missing = _wanted.where((c) => !_isReady(c, states[c]));
    final loaded = states.values.every((s) => s.status != null);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      for (final c in Component.values)
        _componentCard(context, c, states[c] ?? const ComponentState()),
      const SizedBox(height: 28),
      if (!loaded)
        const Center(child: MorphingLoader())
      else if (missing.isEmpty && !_running)
        _primaryButton(
          onPressed: () => _finish(ref),
          icon: const Icon(Icons.arrow_forward_rounded),
          label: l.setupStart,
        )
      else ...[
        _primaryButton(
          onPressed: _running ? null : _install,
          icon: _running
              ? MorphingLoader(size: 22, color: scheme.onPrimary)
              : const Icon(Icons.download_rounded),
          label: _running ? l.setupWorking : l.setupGetReady,
        ),
        if (ytAvailable && !_running) ...[
          const SizedBox(height: 8),
          Center(
            child: TextButton(
              onPressed: () => _finish(ref),
              child: Text(l.setupSkipOptional),
            ),
          ),
        ],
      ],
    ]);
  }

  Widget _componentCard(
      BuildContext context, Component c, ComponentState state) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final status = state.status;
    final ready = _isReady(c, state);

    String subtitle;
    if (state.error != null) {
      subtitle = l.componentFailed(state.error!);
    } else if (state.busy) {
      subtitle = describeProgress(context, state);
    } else if (status == null) {
      subtitle = l.componentChecking;
    } else if (!ready && status.source == ComponentSource.system) {
      subtitle = l.componentStaleSystem(
          status.version ?? l.componentUnknownVersion, AppInfo.name);
    } else if (status.available) {
      final where = switch (status.source) {
        ComponentSource.managed => l.componentInstalledBy(AppInfo.name),
        ComponentSource.system => l.componentFoundOnSystem,
        ComponentSource.custom => l.componentCustom(status.path ?? ''),
        ComponentSource.missing => '',
      };
      subtitle =
          [if (status.version != null) status.version!, where].join(' · ');
    } else {
      subtitle = l.purpose(c);
    }

    return _StepCard(
      leading: ready
          ? _doneIcon(scheme)
          : state.busy
              ? _busyIcon
              : _todoIcon(scheme),
      title: c == Component.ytDlp
          ? c.label
          : '${c.label}  (${l.componentRecommended})',
      subtitle: subtitle,
      error: state.error != null,
      busy: state.busy,
      progress: state.progress,
      trailing: ready || c == Component.ytDlp
          ? null
          : Switch(
              value: _wanted.contains(c),
              onChanged: _running
                  ? null
                  : (v) =>
                      setState(() => v ? _wanted.add(c) : _wanted.remove(c)),
            ),
    );
  }
}

// ------------------------------------------------------------------ android

class _MobileSetup extends ConsumerStatefulWidget {
  const _MobileSetup();

  @override
  ConsumerState<_MobileSetup> createState() => _MobileSetupState();
}

class _MobileSetupState extends ConsumerState<_MobileSetup> {
  String? _version;
  bool _updateEngine = true;
  bool _notify = true;
  bool _notifyAllowed = false;
  bool _running = false;
  bool _updated = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final allowed = await PlatformActions.notificationsAllowed();
    if (mounted) setState(() => _notifyAllowed = allowed);
    try {
      final v =
          await ref.read(engineProvider).version(ref.read(settingsProvider));
      if (mounted) setState(() => _version = v);
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _start() async {
    setState(() {
      _running = true;
      _error = null;
    });
    if (_notify && !_notifyAllowed) {
      final allowed = await PlatformActions.requestNotifications();
      if (mounted) setState(() => _notifyAllowed = allowed);
    }
    if (_updateEngine && !_updated) {
      try {
        final r =
            await ref.read(engineProvider).update(ref.read(settingsProvider));
        _updated = true;
        _version = r.version ?? _version;
      } catch (e) {
        // Stay here and show why; the user can retry or skip.
        if (mounted) {
          setState(() {
            _error = e;
            _running = false;
          });
        }
        return;
      }
    }
    if (mounted) _finish(ref);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l = context.l10n;
    final engineSubtitle = _version == null
        ? l.componentChecking
        : _updated
            ? l.componentUpToDate(_version!)
            : l.setupEngineBuiltIn(_version!);

    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _StepCard(
        leading: _version == null ? _busyIcon : _doneIcon(scheme),
        title: l.setupEngine,
        subtitle: engineSubtitle,
      ),
      _StepCard(
        leading: _updated
            ? _doneIcon(scheme)
            : _running && _updateEngine
                ? _busyIcon
                : _todoIcon(scheme),
        title: l.setupUpdateEngine,
        subtitle: l.setupUpdateEngineSubtitle,
        busy: _running && _updateEngine && !_updated,
        trailing: Switch(
          value: _updateEngine,
          onChanged:
              _running ? null : (v) => setState(() => _updateEngine = v),
        ),
      ),
      _StepCard(
        leading: _notifyAllowed ? _doneIcon(scheme) : _todoIcon(scheme),
        title: l.setupNotifications,
        subtitle:
            _notifyAllowed ? l.setupAllowed : l.setupNotificationsSubtitle,
        trailing: _notifyAllowed
            ? null
            : Switch(
                value: _notify,
                onChanged:
                    _running ? null : (v) => setState(() => _notify = v),
              ),
      ),
      if (_error != null) ...[
        const SizedBox(height: 8),
        ErrorPanel(
          message: l.engineError(_error!),
          details: l.errorDetails(_error!),
          onRetry: _start,
        ),
      ],
      const SizedBox(height: 28),
      _primaryButton(
        onPressed: _running ? null : _start,
        icon: _running
            ? MorphingLoader(size: 22, color: scheme.onPrimary)
            : const Icon(Icons.arrow_forward_rounded),
        label: _running ? l.setupWorking : l.setupStart,
      ),
      if (_error != null && !_running) ...[
        const SizedBox(height: 8),
        Center(
          child: TextButton(
            onPressed: () => _finish(ref),
            child: Text(l.setupSkipOptional),
          ),
        ),
      ],
    ]);
  }
}
