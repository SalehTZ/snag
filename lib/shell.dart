import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/app_info.dart';
import 'core/format.dart';
import 'core/platform_actions.dart';
import 'core/theme/motion.dart';
import 'data/providers.dart';
import 'engine/android_engine.dart';
import 'features/home/home_screen.dart';
import 'features/library/library_screen.dart';
import 'features/queue/download_manager.dart';
import 'features/queue/queue_screen.dart';
import 'features/settings/settings_screen.dart';
import 'l10n/l10n.dart';
import 'widgets/shapes.dart';

enum AppTab { home, queue, library, settings }

class TabNotifier extends Notifier<AppTab> {
  @override
  AppTab build() => AppTab.home;
  void go(AppTab tab) => state = tab;
}

final tabProvider = NotifierProvider<TabNotifier, AppTab>(TabNotifier.new);

/// A URL that arrived from outside (share intent, drag and drop) and should
/// be fetched by the Home screen.
class IncomingUrlNotifier extends Notifier<String?> {
  @override
  String? build() => null;
  void push(String url) => state = url;
  void consume() => state = null;
}

final incomingUrlProvider =
    NotifierProvider<IncomingUrlNotifier, String?>(IncomingUrlNotifier.new);

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  StreamSubscription<String>? _shareSub;

  @override
  void initState() {
    super.initState();
    _shareSub = PlatformActions.sharedText().listen((text) {
      final url = extractUrl(text);
      if (url == null) return;
      ref.read(tabProvider.notifier).go(AppTab.home);
      ref.read(incomingUrlProvider.notifier).push(url);
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Runs again whenever the app language changes.
    final engine = ref.read(engineProvider);
    if (engine is AndroidEngine) {
      final l = context.l10n;
      engine.setNotificationLabels(
          downloading: l.notifyDownloading, locale: l.localeName);
    }
  }

  @override
  void dispose() {
    _shareSub?.cancel();
    super.dispose();
  }

  static const _icons = [
    (Icons.download_outlined, Icons.download_rounded),
    (Icons.downloading_outlined, Icons.downloading_rounded),
    (Icons.video_library_outlined, Icons.video_library_rounded),
    (Icons.tune_outlined, Icons.tune_rounded),
  ];

  static List<String> _labels(AppLocalizations l) =>
      [l.navSnag, l.navQueue, l.navLibrary, l.navSettings];

  Widget _icon(int i, bool selected, int active) {
    final (outlined, filled) = _icons[i];
    final icon = Icon(selected ? filled : outlined);
    if (i != AppTab.queue.index || active == 0) return icon;
    return Badge.count(count: active, child: icon);
  }

  @override
  Widget build(BuildContext context) {
    final tab = ref.watch(tabProvider);
    final active = ref.watch(activeCountProvider);
    final wide = MediaQuery.sizeOf(context).width >= 720;
    final labels = _labels(context.l10n);

    final pages = const [
      HomeScreen(),
      QueueScreen(),
      LibraryScreen(),
      SettingsScreen(),
    ];

    final body = TabStack(index: tab.index, children: pages);

    void go(int i) => ref.read(tabProvider.notifier).go(AppTab.values[i]);

    final shortcuts = <ShortcutActivator, VoidCallback>{
      for (var i = 0; i < 4; i++)
        SingleActivator(LogicalKeyboardKey(0x31 + i), control: true): () => go(i),
    };

    if (wide) {
      return CallbackShortcuts(
        bindings: shortcuts,
        child: Scaffold(
          body: Row(children: [
            NavigationRail(
              selectedIndex: tab.index,
              onDestinationSelected: go,
              labelType: NavigationRailLabelType.all,
              groupAlignment: -0.85,
              leading: Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 24),
                child: Tooltip(
                  message: AppInfo.name,
                  child: ShapeIcon(
                    icon: Icons.south_rounded,
                    size: 48,
                    lobes: 8,
                    spin: false,
                    color: Theme.of(context).colorScheme.primary,
                    iconColor: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
              ),
              destinations: [
                for (var i = 0; i < _icons.length; i++)
                  NavigationRailDestination(
                    icon: _icon(i, false, active),
                    selectedIcon: _icon(i, true, active),
                    label: Text(labels[i]),
                  ),
              ],
            ),
            Expanded(child: body),
          ]),
        ),
      );
    }

    return Scaffold(
      body: body,
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab.index,
        onDestinationSelected: go,
        destinations: [
          for (var i = 0; i < _icons.length; i++)
            NavigationDestination(
              icon: _icon(i, false, active),
              selectedIcon: _icon(i, true, active),
              label: labels[i],
            ),
        ],
      ),
    );
  }
}

/// Shows one page at a time like a tab switcher, but keeps every page that
/// has been opened alive, so a half-typed link or a scroll position survives
/// a trip to another tab. Pages are built the first time they are shown.
class TabStack extends StatefulWidget {
  const TabStack({super.key, required this.index, required this.children});

  final int index;
  final List<Widget> children;

  @override
  State<TabStack> createState() => _TabStackState();
}

class _TabStackState extends State<TabStack>
    with SingleTickerProviderStateMixin {
  late final _visited = {widget.index};
  late final _controller =
      AnimationController(vsync: this, duration: Motion.medium, value: 1);
  late final _fade = CurvedAnimation(parent: _controller, curve: Motion.effects);
  late final _slide = Tween(begin: const Offset(0, 0.015), end: Offset.zero)
      .animate(_fade);

  @override
  void didUpdateWidget(TabStack old) {
    super.didUpdateWidget(old);
    if (old.index == widget.index) return;
    _visited.add(widget.index);
    _controller.duration = Motion.of(context, Motion.medium);
    _controller.forward(from: 0);
  }

  @override
  void dispose() {
    _fade.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: IndexedStack(
            index: widget.index,
            sizing: StackFit.expand,
            children: [
              for (var i = 0; i < widget.children.length; i++)
                _page(i, i == widget.index),
            ],
          ),
        ),
      );

  Widget _page(int i, bool active) {
    if (!_visited.contains(i)) return const SizedBox.shrink();
    // Hidden pages stay mounted but must not animate or hold focus.
    return TickerMode(
      enabled: active,
      child: ExcludeFocus(excluding: !active, child: widget.children[i]),
    );
  }
}
