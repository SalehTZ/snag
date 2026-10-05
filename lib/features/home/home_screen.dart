import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_info.dart';
import '../../core/format.dart';
import '../../core/platform_actions.dart';
import '../../core/theme/motion.dart';
import '../../core/theme/theme.dart';
import '../../data/providers.dart';
import '../../engine/models.dart';
import '../../engine/ytdlp_engine.dart';
import '../../shell.dart';
import '../../widgets/common.dart';
import '../../widgets/shapes.dart';
import '../download_sheet/download_sheet.dart';
import '../queue/download_manager.dart';
import 'recent_strip.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  bool _fetching = false;
  bool _dragging = false;
  EngineException? _error;
  String? _clipboardUrl;
  String? _dismissedClipboard;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller.addListener(() => setState(() {}));
    _checkClipboard();
    WidgetsBinding.instance.addPostFrameCallback((_) => _consumeIncoming());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _checkClipboard();
  }

  Future<void> _checkClipboard() async {
    if (!ref.read(settingsProvider).autoPaste) return;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      final url = extractUrl(data?.text);
      if (!mounted) return;
      setState(() => _clipboardUrl =
          url != null && url != _dismissedClipboard && url != _controller.text
              ? url
              : null);
    } catch (_) {}
  }

  void _consumeIncoming() {
    final url = ref.read(incomingUrlProvider);
    if (url == null) return;
    ref.read(incomingUrlProvider.notifier).consume();
    _controller.text = url;
    _fetch();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final url = extractUrl(data?.text) ?? data?.text?.trim();
    if (url == null || url.isEmpty) {
      if (mounted) showSnack(context, 'The clipboard has no link in it.');
      return;
    }
    _controller.text = url;
    setState(() => _clipboardUrl = null);
  }

  String? get _url {
    final text = _controller.text.trim();
    if (text.isEmpty) return null;
    return extractUrl(text) ?? (text.contains('.') ? 'https://$text' : null);
  }

  Future<void> _fetch() async {
    final url = _url;
    if (url == null) {
      setState(() => _error = EngineException(
          'That does not look like a link. Paste a full address, like '
          'https://youtube.com/watch?v=...'));
      return;
    }
    final request = ++_request;
    setState(() {
      _fetching = true;
      _error = null;
    });
    try {
      final info = await ref
          .read(engineProvider)
          .fetchInfo(url, ref.read(settingsProvider));
      if (!mounted || request != _request) return;
      setState(() => _fetching = false);
      final queued = await showDownloadSheet(context, info);
      if (queued == true && mounted) {
        _controller.clear();
        _dismissedClipboard = url;
        setState(() => _clipboardUrl = null);
      }
    } catch (e) {
      if (!mounted || request != _request) return;
      setState(() {
        _fetching = false;
        _error = e is EngineException ? e : EngineException('$e');
      });
    }
  }

  void _cancelFetch() {
    _request++;
    setState(() => _fetching = false);
  }

  /// Skip the options sheet: queue straight away with the user's defaults.
  void _quickDownload() {
    final url = _url;
    if (url == null) {
      _fetch();
      return;
    }
    final s = ref.read(settingsProvider);
    ref.read(downloadManagerProvider.notifier).enqueue(
          DownloadSpec(
            url: url,
            mode: s.defaultMode,
            quality: s.defaultQuality,
            audioFormat: s.defaultAudioFormat,
          ),
          MediaMeta(title: url),
        );
    _controller.clear();
    _dismissedClipboard = url;
    setState(() {
      _clipboardUrl = null;
      _error = null;
    });
    showSnack(context, 'Added to the queue',
        actionLabel: 'View',
        onAction: () => ref.read(tabProvider.notifier).go(AppTab.queue));
  }

  void _onDrop(DropDoneDetails details) {
    final text = details.rawText ??
        details.files.map((f) => f.path).join(' ');
    final url = extractUrl(text);
    setState(() => _dragging = false);
    if (url == null) {
      showSnack(context, 'Drop a link from your browser, not a file.');
      return;
    }
    _controller.text = url;
    _fetch();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(incomingUrlProvider, (_, next) {
      if (next != null) _consumeIncoming();
    });

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final width = MediaQuery.sizeOf(context).width;
    final compact = width < 600;
    final hasText = _controller.text.trim().isNotEmpty;

    final content = ReadableWidth(
      maxWidth: 720,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: compact ? 20 : 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: compact ? 40 : 88),
            Text.rich(
              TextSpan(children: [
                const TextSpan(text: 'Snag it'),
                TextSpan(text: '.', style: TextStyle(color: scheme.primary)),
              ]),
              style: (compact
                      ? theme.textTheme.displayMedium
                      : theme.textTheme.displayLarge)
                  ?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 12),
            Text(
              'Paste a link from YouTube, Instagram, TikTok, X, SoundCloud, '
              'Vimeo and well over a thousand other sites.',
              style: theme.textTheme.titleMedium?.copyWith(
                  color: scheme.onSurfaceVariant, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 32),
            _UrlField(
              controller: _controller,
              focusNode: _focus,
              enabled: !_fetching,
              onSubmit: _fetch,
              onPaste: _paste,
              onClear: () {
                _controller.clear();
                setState(() => _error = null);
              },
            ),
            _ClipboardSuggestion(
              url: _clipboardUrl,
              onUse: () {
                _controller.text = _clipboardUrl!;
                setState(() => _clipboardUrl = null);
                _fetch();
              },
              onDismiss: () => setState(() {
                _dismissedClipboard = _clipboardUrl;
                _clipboardUrl = null;
              }),
            ),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(
                child: _SnagButton(
                  fetching: _fetching,
                  enabled: hasText,
                  onPressed: _fetching ? _cancelFetch : _fetch,
                ),
              ),
              const SizedBox(width: 12),
              Tooltip(
                message: 'Download now with your default settings',
                child: SizedBox.square(
                  dimension: 64,
                  child: IconButton.filledTonal(
                    onPressed: hasText && !_fetching ? _quickDownload : null,
                    icon: const Icon(Icons.bolt_rounded, size: 28),
                    style: IconButton.styleFrom(
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusLg - 8)),
                    ),
                  ),
                ),
              ),
            ]),
            AnimatedSize(
              duration: Motion.of(context, Motion.medium),
              curve: Motion.spatial,
              child: _error == null
                  ? const SizedBox(width: double.infinity)
                  : Padding(
                      padding: const EdgeInsets.only(top: 20),
                      child: ErrorPanel(
                        message: _error!.message,
                        details: _error!.details,
                        onRetry: _fetch,
                      ),
                    ),
            ),
            const SizedBox(height: 40),
            const RecentStrip(),
            const SizedBox(height: 24),
            Center(
              child: TextButton.icon(
                onPressed: () =>
                    PlatformActions.openLink(AppInfo.supportedSitesUrl),
                icon: const Icon(Icons.public_rounded, size: 18),
                label: const Text('See every supported site'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );

    final page = Scaffold(
      body: SafeArea(child: SingleChildScrollView(child: content)),
    );

    if (!isDesktop) return page;
    return DropTarget(
      onDragEntered: (_) => setState(() => _dragging = true),
      onDragExited: (_) => setState(() => _dragging = false),
      onDragDone: _onDrop,
      child: Stack(children: [
        page,
        IgnorePointer(
          child: AnimatedOpacity(
            opacity: _dragging ? 1 : 0,
            duration: Motion.of(context, Motion.short),
            child: Container(
              color: scheme.primaryContainer.withValues(alpha: 0.92),
              alignment: Alignment.center,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                ShapeIcon(
                  icon: Icons.add_link_rounded,
                  color: scheme.primary,
                  iconColor: scheme.onPrimary,
                ),
                const SizedBox(height: 24),
                Text('Drop the link to snag it',
                    style: theme.textTheme.headlineMedium
                        ?.copyWith(color: scheme.onPrimaryContainer)),
              ]),
            ),
          ),
        ),
      ]),
    );
  }
}

class _UrlField extends StatelessWidget {
  const _UrlField({
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmit,
    required this.onPaste,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final VoidCallback onSubmit;
  final VoidCallback onPaste;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasText = controller.text.isNotEmpty;
    return TextField(
      controller: controller,
      focusNode: focusNode,
      enabled: enabled,
      autofocus: isDesktop,
      keyboardType: TextInputType.url,
      textInputAction: TextInputAction.go,
      autocorrect: false,
      enableSuggestions: false,
      onSubmitted: (_) => onSubmit(),
      style: theme.textTheme.titleMedium,
      decoration: InputDecoration(
        hintText: 'https://...',
        prefixIcon: const Padding(
          padding: EdgeInsetsDirectional.only(start: 20, end: 8),
          child: Icon(Icons.link_rounded),
        ),
        suffixIcon: Padding(
          padding: const EdgeInsetsDirectional.only(end: 8),
          child: hasText
              ? IconButton(
                  tooltip: 'Clear',
                  onPressed: enabled ? onClear : null,
                  icon: const Icon(Icons.close_rounded),
                )
              : TextButton.icon(
                  onPressed: enabled ? onPaste : null,
                  icon: const Icon(Icons.content_paste_rounded, size: 18),
                  label: const Text('Paste'),
                ),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      ),
    );
  }
}

class _ClipboardSuggestion extends StatelessWidget {
  const _ClipboardSuggestion({
    required this.url,
    required this.onUse,
    required this.onDismiss,
  });

  final String? url;
  final VoidCallback onUse;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedSize(
      duration: Motion.of(context, Motion.medium),
      curve: Motion.spatial,
      alignment: Alignment.topLeft,
      child: url == null
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Material(
                color: scheme.tertiaryContainer,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                  onTap: onUse,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 4, 8),
                    child: Row(children: [
                      Icon(Icons.content_paste_go_rounded,
                          color: scheme.onTertiaryContainer, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Link in your clipboard',
                                style: theme.textTheme.labelLarge?.copyWith(
                                    color: scheme.onTertiaryContainer)),
                            Text(
                              url!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.bodySmall?.copyWith(
                                  color: scheme.onTertiaryContainer),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Dismiss',
                        onPressed: onDismiss,
                        icon: Icon(Icons.close_rounded,
                            color: scheme.onTertiaryContainer),
                      ),
                    ]),
                  ),
                ),
              ),
            ),
    );
  }
}

/// The hero button. Morphs into a loader while fetching (and then acts as
/// a cancel button).
class _SnagButton extends StatelessWidget {
  const _SnagButton({
    required this.fetching,
    required this.enabled,
    required this.onPressed,
  });

  final bool fetching;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedContainer(
      duration: Motion.of(context, Motion.medium),
      curve: Motion.spatial,
      height: 64,
      child: FilledButton(
        onPressed: enabled || fetching ? onPressed : null,
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(fetching ? AppTheme.radiusMd : 100)),
          textStyle: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        child: AnimatedSwitcher(
          duration: Motion.of(context, Motion.short),
          child: fetching
              ? Row(
                  key: const ValueKey('loading'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MorphingLoader(size: 26, color: scheme.onPrimary),
                    const SizedBox(width: 14),
                    const Flexible(
                      child: Text('Looking it up... tap to cancel',
                          textAlign: TextAlign.center),
                    ),
                  ],
                )
              : const Row(
                  key: ValueKey('idle'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.south_rounded),
                    SizedBox(width: 10),
                    Text('Snag'),
                  ],
                ),
        ),
      ),
    );
  }
}
