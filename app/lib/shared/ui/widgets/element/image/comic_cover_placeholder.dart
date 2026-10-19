import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
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
    final HentaiColorScheme semantic = context.hentai;
    return switch (variant) {
      ComicCoverPlaceholderVariant.card => _buildCard(semantic),
      ComicCoverPlaceholderVariant.detail => _buildDetail(semantic),
    };
  }

  Widget _buildCard(HentaiColorScheme semantic) {
    return switch (kind) {
      ComicCoverPlaceholderKind.loading => ColoredBox(
        color: semantic.imagePlaceholder,
      ),
      ComicCoverPlaceholderKind.noCover => ColoredBox(
        color: semantic.imageFallback,
        child: Center(
          child: Icon(LucideIcons.imageOff, color: semantic.iconSecondary),
        ),
      ),
      ComicCoverPlaceholderKind.error => ColoredBox(
        color: semantic.imageFallback,
        child: Center(
          child: Icon(LucideIcons.circleAlert, color: semantic.textTertiary),
        ),
      ),
    };
  }

  Widget _buildDetail(HentaiColorScheme semantic) {
    final double resolvedIconSize = iconSize ?? 40;
    return switch (kind) {
      ComicCoverPlaceholderKind.loading => const SizedBox.expand(),
      ComicCoverPlaceholderKind.noCover => Center(
        child: Icon(
          LucideIcons.imageOff,
          color: semantic.iconSecondary,
          size: resolvedIconSize,
        ),
      ),
      ComicCoverPlaceholderKind.error => Center(
        child: Icon(
          LucideIcons.circleAlert,
          color: semantic.textTertiary,
          size: resolvedIconSize,
        ),
      ),
    };
  }
}
