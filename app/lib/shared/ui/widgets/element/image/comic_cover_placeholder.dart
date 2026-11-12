import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

enum ComicCoverPlaceholderVariant { card, detail }

enum ComicCoverPlaceholderKind { loading, noCover, error }

class ComicCoverPlaceholder extends StatelessWidget {
  const ComicCoverPlaceholder({
    super.key,
    required this.variant,
    required this.kind,
    this.iconSize,
  });

  final ComicCoverPlaceholderVariant variant;
  final ComicCoverPlaceholderKind kind;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final ColorScheme colorScheme = Theme.of(context).colorScheme;
    final double resolvedIconSize = iconSize ?? 40;
    return switch (variant) {
      ComicCoverPlaceholderVariant.card => switch (kind) {
        ComicCoverPlaceholderKind.loading => ColoredBox(
          color: colorScheme.surfaceContainerHighest,
        ),
        ComicCoverPlaceholderKind.noCover => ColoredBox(
          color: colorScheme.surfaceContainerHigh,
          child: Center(
            child: Icon(
              LucideIcons.imageOff,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ComicCoverPlaceholderKind.error => ColoredBox(
          color: colorScheme.surfaceContainerHigh,
          child: Center(
            child: Icon(
              LucideIcons.circleAlert,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      },
      ComicCoverPlaceholderVariant.detail => switch (kind) {
        ComicCoverPlaceholderKind.loading => const SizedBox.expand(),
        ComicCoverPlaceholderKind.noCover => Center(
          child: Icon(
            LucideIcons.imageOff,
            color: colorScheme.onSurfaceVariant,
            size: resolvedIconSize,
          ),
        ),
        ComicCoverPlaceholderKind.error => Center(
          child: Icon(
            LucideIcons.circleAlert,
            color: colorScheme.onSurfaceVariant,
            size: resolvedIconSize,
          ),
        ),
      },
    };
  }
}
