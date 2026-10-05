import 'package:flutter/material.dart';

import '../../core/app_info.dart';
import '../../core/platform_actions.dart';
import '../../core/theme/theme.dart';
import '../../widgets/shapes.dart';

/// The donation ask: honest, friendly, never a nag.
class SupportCard extends StatelessWidget {
  const SupportCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
            child: Text('Keep ${AppInfo.name} free',
                style: theme.textTheme.titleLarge
                    ?.copyWith(color: scheme.onTertiaryContainer)),
          ),
        ]),
        const SizedBox(height: 12),
        Text(
          '${AppInfo.name} has no ads, no tracking and no paywall, and it '
          'never will. If it saved you some time, a small donation keeps '
          'updates coming.',
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
            label: const Text('GitHub Sponsors'),
          ),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
                foregroundColor: scheme.onTertiaryContainer),
            onPressed: () => PlatformActions.openLink(AppInfo.kofiUrl),
            icon: const Icon(Icons.local_cafe_rounded),
            label: const Text('Buy a coffee'),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
                foregroundColor: scheme.onTertiaryContainer),
            onPressed: () => PlatformActions.openLink(AppInfo.repoUrl),
            icon: const Icon(Icons.star_outline_rounded),
            label: const Text('Star on GitHub'),
          ),
        ]),
      ]),
    );
  }
}
