import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
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
    final ColorScheme cs = Theme.of(context).colorScheme;
    return switch (variant) {
      ComicCoverPlaceholderVariant.card => _buildCard(cs),
      ComicCoverPlaceholderVariant.detail => _buildDetail(cs),
    };
  }

  Widget _buildCard(ColorScheme cs) {
    return switch (kind) {
      ComicCoverPlaceholderKind.loading => ColoredBox(
        color: cs.hentai.imagePlaceholder,
      ),
      ComicCoverPlaceholderKind.noCover => ColoredBox(
        color: cs.hentai.imageFallback,
        child: Center(
          child: Icon(
            LucideIcons.imageOff,
            color: cs.hentai.iconSecondary,
          ),
        ),
      ),
      ComicCoverPlaceholderKind.error => ColoredBox(
        color: cs.hentai.imageFallback,
        child: Center(
          child: Icon(
            LucideIcons.circleAlert,
            color: cs.hentai.textTertiary,
          ),
        ),
      ),
    };
  }

  Widget _buildDetail(ColorScheme cs) {
    final double resolvedIconSize = iconSize ?? 40;
    return switch (kind) {
      ComicCoverPlaceholderKind.loading => const SizedBox.expand(),
      ComicCoverPlaceholderKind.noCover => Center(
        child: Icon(
          LucideIcons.imageOff,
          color: cs.hentai.iconSecondary,
          size: resolvedIconSize,
        ),
      ),
      ComicCoverPlaceholderKind.error => Center(
        child: Icon(
          LucideIcons.circleAlert,
          color: cs.hentai.textTertiary,
          size: resolvedIconSize,
        ),
      ),
    };
  }
}
