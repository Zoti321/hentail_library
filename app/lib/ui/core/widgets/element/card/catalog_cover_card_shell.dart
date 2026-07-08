import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// Shared chrome + 2:3 edge-to-edge cover for catalog grid cards.
///
/// Used internally by [ComicCard] / [SeriesCard]; pages should keep using
/// those domain cards rather than this shell directly.
class CatalogCoverCardShell extends HookWidget {
  const CatalogCoverCardShell({
    super.key,
    required this.cover,
    required this.info,
    this.onTap,
    this.onSecondaryTapUp,
  });

  final Widget cover;
  final Widget Function(bool isHover) info;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final ValueNotifier<bool> isHover = useState(false);
    final BorderRadius cardRadius = BorderRadius.circular(tokens.radius.xs);

    return GestureDetector(
      onTap: onTap,
      onSecondaryTapUp: onSecondaryTapUp,
      child: MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => isHover.value = true,
        onExit: (_) => isHover.value = false,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            borderRadius: cardRadius,
            color: cs.surface,
            border: Border.all(color: cs.hentai.borderSubtle),
            boxShadow: isHover.value
                ? <BoxShadow>[
                    BoxShadow(
                      color: cs.hentai.cardShadowHover,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : <BoxShadow>[
                    BoxShadow(
                      color: cs.hentai.cardShadow,
                      blurRadius: 2,
                      offset: const Offset(0, 1),
                    ),
                  ],
          ),
          child: ClipRRect(
            borderRadius: cardRadius,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              spacing: tokens.spacing.md,
              children: <Widget>[
                AspectRatio(aspectRatio: 2 / 3, child: cover),
                Padding(
                  padding: EdgeInsets.only(
                    left: tokens.spacing.sm,
                    right: tokens.spacing.sm,
                    bottom: tokens.spacing.sm,
                  ),
                  child: info(isHover.value),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
