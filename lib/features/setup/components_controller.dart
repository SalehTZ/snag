import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/providers.dart';
import '../../engine/binary_manager.dart';

@immutable
class ComponentState {
  const ComponentState({
    this.status,
    this.busy = false,
    this.progress,
    this.stage,
    this.error,
    this.message,
  });

  final ComponentStatus? status;
  final bool busy;
  final double? progress;
  final String? stage;
  final String? error;
  final String? message;

  bool get available => status?.available ?? false;
}

/// Desktop helper binaries: status, install, update.
class ComponentsController extends Notifier<Map<Component, ComponentState>> {
  @override
  Map<Component, ComponentState> build() {
    Future.microtask(refresh);
    return {for (final c in Component.values) c: const ComponentState()};
  }

  BinaryManager get _bins => ref.read(binaryManagerProvider);

  void _set(Component c, ComponentState s) => state = {...state, c: s};

  Future<void> refresh() async {
    final settings = ref.read(settingsProvider);
    for (final c in Component.values) {
      final override = switch (c) {
        Component.ytDlp => settings.ytDlpPath,
        Component.ffmpeg => settings.ffmpegPath,
        Component.deno => null,
      };
      final status =
          await _bins.withVersion(await _bins.resolve(c, override: override));
      if (!ref.mounted) return;
      _set(c, ComponentState(status: status));
    }
  }

  Future<bool> install(Component c) async {
    _set(c, ComponentState(status: state[c]?.status, busy: true, stage: 'Starting'));
    try {
      await _bins.install(c, onProgress: (fraction, stage) {
        if (!ref.mounted) return;
        _set(c, ComponentState(
          status: state[c]?.status,
          busy: true,
          progress: fraction,
          stage: stage,
        ));
      });
      final status = await _bins.withVersion(await _bins.resolve(c));
      _set(c, ComponentState(status: status, message: 'Installed'));
      return true;
    } catch (e) {
      _set(c, ComponentState(status: state[c]?.status, error: '$e'));
      return false;
    }
  }

  Future<void> updateYtDlp() async {
    const c = Component.ytDlp;
    _set(c, ComponentState(status: state[c]?.status, busy: true, stage: 'Updating'));
    try {
      final engine = ref.read(engineProvider);
      final message = await engine.update(ref.read(settingsProvider));
      final status = await _bins.withVersion(await _bins.resolve(c,
          override: ref.read(settingsProvider).ytDlpPath));
      _set(c, ComponentState(status: status, message: message));
    } catch (e) {
      _set(c, ComponentState(status: state[c]?.status, error: '$e'));
    }
  }
}

final componentsProvider =
    NotifierProvider<ComponentsController, Map<Component, ComponentState>>(
        ComponentsController.new);
