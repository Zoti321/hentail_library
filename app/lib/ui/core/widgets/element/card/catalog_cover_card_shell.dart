import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// Shared chrome + 2:3 cover frame for catalog grid cards.
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

  final Widget Function(bool isHover) cover;
  final Widget Function(bool isHover) info;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final ValueNotifier<bool> isHover = useState(false);

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
          padding: EdgeInsets.all(tokens.spacing.sm),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(tokens.radius.lg),
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
                : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            spacing: 12,
            children: <Widget>[
              _CatalogCoverFrame(
                isHover: isHover.value,
                child: cover(isHover.value),
              ),
              info(isHover.value),
            ],
          ),
        ),
      ),
    );
  }
}

class _CatalogCoverFrame extends StatelessWidget {
  const _CatalogCoverFrame({required this.isHover, required this.child});

  final bool isHover;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(tokens.radius.md),
        color: cs.hentai.imagePlaceholder,
        boxShadow: isHover
            ? <BoxShadow>[
                BoxShadow(
                  color: cs.hentai.cardShadowHover,
                  blurRadius: 20,
                  offset: Offset.zero,
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
        borderRadius: BorderRadius.circular(tokens.radius.md),
        child: AspectRatio(aspectRatio: 2 / 3, child: child),
      ),
    );
  }
}
