import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/catalog_cover_card_shell.dart';

/// Non-interactive 2:3 cover placeholder for catalog loading grids.
class CatalogCoverSkeletonTile extends StatelessWidget {
  const CatalogCoverSkeletonTile({super.key});

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final Color bar = cs.hentai.imagePlaceholder;
    return ExcludeSemantics(
      child: CatalogCoverCardShell(
        cover: ColoredBox(color: bar),
        info: (_) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: tokens.spacing.xs,
          children: <Widget>[
            ColoredBox(
              color: bar,
              child: const SizedBox(width: double.infinity, height: 14),
            ),
            ColoredBox(
              color: bar,
              child: const SizedBox(width: 72, height: 10),
            ),
          ],
        ),
      ),
    );
  }
}
