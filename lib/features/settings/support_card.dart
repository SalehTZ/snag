import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/app_info.dart';
import '../../core/platform_actions.dart';
import '../../core/theme/theme.dart';
import '../../l10n/l10n.dart';
import '../../widgets/common.dart';
import '../../widgets/shapes.dart';

/// The donation ask: honest, friendly, never a nag.
class SupportCard extends StatelessWidget {
  const SupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l = context.l10n;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ShapeIcon(
            icon: Icons.favorite_rounded,
            size: 52,
            lobes: 6,
            color: scheme.tertiary,
            iconColor: scheme.onTertiary,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(l.supportTitle(AppInfo.name),
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: scheme.onTertiaryContainer)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(
          l.supportBody(AppInfo.name),
          style: theme.textTheme.bodyMedium
              ?.copyWith(color: scheme.onTertiaryContainer),
        ),
        const SizedBox(height: 16),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: scheme.tertiary,
              foregroundColor: scheme.onTertiary,
            ),
            onPressed: () => PlatformActions.openLink(AppInfo.sponsorUrl),
            icon: const Icon(Icons.favorite_rounded),
            label: Text(l.supportSponsors),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onTertiaryContainer),
            onPressed: () => showCryptoSheet(context),
            icon: const Icon(Icons.currency_bitcoin_rounded),
            label: Text(l.supportCrypto),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onTertiaryContainer),
            onPressed: () => PlatformActions.openLink(AppInfo.kofiUrl),
            icon: const Icon(Icons.local_cafe_rounded),
            label: Text(l.supportCoffee),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
                foregroundColor: scheme.onTertiaryContainer),
            onPressed: () => PlatformActions.openLink(AppInfo.repoUrl),
            icon: const Icon(Icons.star_outline_rounded),
            label: Text(l.supportStar),
          ),
        ]),
      ]),
    );
  }
}

/// Wallet addresses with one-tap copy. Addresses are always shown in full
/// and left-to-right, so donors can compare them with what they paste.
Future<void> showCryptoSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) {
      final theme = Theme.of(context);
      final scheme = theme.colorScheme;
      final l = context.l10n;
      return ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
        children: [
          Text(l.cryptoTitle, style: theme.textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(l.cryptoBody,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: scheme.onSurfaceVariant)),
          const SizedBox(height: 16),
          for (final (i, w) in AppInfo.wallets.indexed)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 8, 12),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Row(children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 8,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(w.network, style: theme.textTheme.titleSmall),
                          if (i == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: scheme.tertiaryContainer,
                                borderRadius: BorderRadius.circular(100),
                              ),
                              child: Text(l.cryptoLowestFees,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                      color: scheme.onTertiaryContainer)),
                            ),
                        ],
                      ),
                      Text(w.coins,
                          textDirection: TextDirection.ltr,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 6),
                      SelectableText(
                        w.address,
                        textDirection: TextDirection.ltr,
                        style: monoStyle.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: l.cryptoCopy,
                  icon: const Icon(Icons.copy_rounded),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: w.address));
                    showSnack(context, l.cryptoCopied(w.network));
                  },
                ),
              ]),
            ),
        ],
      );
    },
  );
}

