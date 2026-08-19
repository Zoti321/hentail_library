import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/ui/core/interaction/app_motion.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

/// Shared chrome + 2:3 cover slot for catalog grid cards.
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
    this.onLongPressStart,
    this.semanticLabel,
  });

  final Widget cover;
  final Widget Function(bool isHover) info;
  final VoidCallback? onTap;
  final GestureTapUpCallback? onSecondaryTapUp;
  final GestureLongPressStartCallback? onLongPressStart;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final ValueNotifier<bool> isHover = useState(false);
    final ValueNotifier<bool> isFocused = useState(false);
    final BorderRadius cardRadius = BorderRadius.circular(tokens.radius.xs);
    final bool highlighted = isHover.value || isFocused.value;
    final Duration motion = motionDurationOf(
      context,
      const Duration(milliseconds: 200),
    );

    Widget card = GestureDetector(
      onTap: onTap,
      onSecondaryTapUp: onSecondaryTapUp,
      onLongPressStart: onLongPressStart,
      child: AnimatedContainer(
        duration: motion,
        decoration: BoxDecoration(
          borderRadius: cardRadius,
          color: cs.surface,
          border: Border.all(
            color: isFocused.value ? cs.primary : cs.hentai.borderSubtle,
          ),
          boxShadow: highlighted
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
                child: info(highlighted),
              ),
            ],
          ),
        ),
      ),
    );

    card = FocusableActionDetector(
      enabled: onTap != null,
      mouseCursor: onTap != null
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      onShowHoverHighlight: (bool value) => isHover.value = value,
      onShowFocusHighlight: (bool value) => isFocused.value = value,
      actions: <Type, Action<Intent>>{
        ActivateIntent: CallbackAction<ActivateIntent>(
          onInvoke: (ActivateIntent intent) {
            onTap?.call();
            return null;
          },
        ),
      },
      child: card,
    );

    return RepaintBoundary(
      child: Semantics(
        button: onTap != null,
        enabled: onTap != null,
        label: semanticLabel,
        child: card,
      ),
    );
  }
}
