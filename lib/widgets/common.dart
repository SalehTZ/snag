import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/format.dart';
import '../core/theme/motion.dart';
import '../core/theme/theme.dart';
import 'shapes.dart';

/// Rounded thumbnail with graceful loading/error states and an optional
/// duration badge.
class MediaThumb extends StatelessWidget {
  const MediaThumb({
    super.key,
    required this.url,
    this.width = 128,
    this.radius = AppTheme.radiusMd,
    this.duration,
    this.icon = Icons.movie_outlined,
  });

  final String? url;
  final double width;
  final double radius;
  final double? duration;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = ColoredBox(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(icon, color: scheme.onSurfaceVariant, size: width * 0.22),
      ),
    );
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 16 / 9,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(fit: StackFit.expand, children: [
            if (url == null)
              placeholder
            else
              Image.network(
                url!,
                fit: BoxFit.cover,
                cacheWidth: (width * MediaQuery.devicePixelRatioOf(context))
                    .round(),
                errorBuilder: (_, _, _) => placeholder,
                frameBuilder: (context, child, frame, sync) => sync
                    ? child
                    : AnimatedOpacity(
                        opacity: frame == null ? 0 : 1,
                        duration: Motion.of(context, Motion.short),
                        child: frame == null ? placeholder : child,
                      ),
              ),
            if (duration != null && duration! > 0)
              Positioned(
                right: 6,
                bottom: 6,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    formatDuration(duration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ),
              ),
          ]),
        ),
      ),
    );
  }
}

/// Centered empty/first-run state. Kept distinct per situation by callers.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.action,
    this.shapeColor,
  });

  final IconData icon;
  final String title;
  final String body;
  final Widget? action;
  final Color? shapeColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            ShapeIcon(icon: icon, color: shapeColor),
            const SizedBox(height: 28),
            Text(title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(body,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            if (action != null) ...[const SizedBox(height: 24), action!],
          ]),
        ),
      ),
    );
  }
}

/// Error with a plain-language message, optional raw details and actions.
class ErrorPanel extends StatefulWidget {
  const ErrorPanel({
    super.key,
    required this.message,
    this.details,
    this.onRetry,
    this.compact = false,
  });

  final String message;
  final String? details;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  State<ErrorPanel> createState() => _ErrorPanelState();
}

class _ErrorPanelState extends State<ErrorPanel> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final hasDetails =
        widget.details != null && widget.details!.trim() != widget.message;
    return Container(
      padding: EdgeInsets.all(widget.compact ? 12 : 16),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd + 4),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.error_outline_rounded, color: scheme.onErrorContainer),
          const SizedBox(width: 12),
          Expanded(
            child: SelectableText(
              widget.message,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onErrorContainer),
            ),
          ),
        ]),
        if (hasDetails || widget.onRetry != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Wrap(spacing: 4, children: [
              if (widget.onRetry != null)
                TextButton.icon(
                  onPressed: widget.onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try again'),
                  style: TextButton.styleFrom(
                      foregroundColor: scheme.onErrorContainer),
                ),
              if (hasDetails)
                TextButton.icon(
                  onPressed: () => setState(() => _open = !_open),
                  icon: Icon(_open
                      ? Icons.expand_less_rounded
                      : Icons.expand_more_rounded),
                  label: Text(_open ? 'Hide details' : 'Show details'),
                  style: TextButton.styleFrom(
                      foregroundColor: scheme.onErrorContainer),
                ),
              if (hasDetails && _open)
                TextButton.icon(
                  onPressed: () =>
                      Clipboard.setData(ClipboardData(text: widget.details!)),
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy log'),
                  style: TextButton.styleFrom(
                      foregroundColor: scheme.onErrorContainer),
                ),
            ]),
          ),
        AnimatedSize(
          duration: Motion.of(context, Motion.medium),
          curve: Motion.spatial,
          alignment: Alignment.topCenter,
          child: !_open || !hasDetails
              ? const SizedBox(width: double.infinity)
              : Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(maxHeight: 220),
                  decoration: BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(AppTheme.radiusSm),
                  ),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      widget.details!,
                      style: monoStyle.copyWith(fontSize: 12, height: 1.4),
                    ),
                  ),
                ),
        ),
      ]),
    );
  }
}

/// A section label in lists and settings.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.text, {super.key, this.trailing});
  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 8, 8),
      child: Row(children: [
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.titleSmall
                ?.copyWith(color: theme.colorScheme.primary),
          ),
        ),
        ?trailing,
      ]),
    );
  }
}

/// Wraps a page body so content never stretches past a readable width on
/// big desktop windows.
class ReadableWidth extends StatelessWidget {
  const ReadableWidth({super.key, required this.child, this.maxWidth = 840});
  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      );
}

void showSnack(BuildContext context, String message,
    {String? actionLabel, VoidCallback? onAction}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(SnackBar(
    content: Text(message),
    action: actionLabel == null
        ? null
        : SnackBarAction(label: actionLabel, onPressed: onAction ?? () {}),
  ));
}

/// Large, expressive page header used instead of the stock small AppBar.
class PageHeader extends StatelessWidget implements PreferredSizeWidget {
  const PageHeader({super.key, required this.title, this.actions = const []});

  final String title;
  final List<Widget> actions;

  @override
  Size get preferredSize => const Size.fromHeight(96);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final canPop = Navigator.of(context).canPop();
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: preferredSize.height,
        child: Padding(
          padding: EdgeInsets.fromLTRB(canPop ? 8 : 24, 16, 12, 8),
          child: Row(children: [
            if (canPop) ...[
              const BackButton(),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.headlineLarge
                      ?.copyWith(color: theme.colorScheme.onSurface),
                ),
              ),
            ),
            ...actions,
          ]),
        ),
      ),
    );
  }
}

/// Monospace with real fallbacks; a bare 'monospace' does not resolve on
/// every desktop platform.
const monoStyle = TextStyle(
  fontFamily: 'monospace',
  fontFamilyFallback: ['Cascadia Mono', 'Consolas', 'Menlo', 'SF Mono', 'DejaVu Sans Mono', 'Noto Sans Mono'],
);
