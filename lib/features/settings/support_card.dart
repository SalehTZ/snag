import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/platform_actions.dart';
import '../../core/theme/theme.dart';
import '../../l10n/l10n.dart';
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
