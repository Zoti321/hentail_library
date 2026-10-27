import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/motion/md3e_motion.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Shared corner radius for catalog grid [Md3eComicCard] and list [Md3eComicListItem].
const double kMd3eComicCardRadius = 12;

/// Horizontal inset for text blocks (card info + list row).
const double kMd3eComicCatalogContentHorizontalPadding = 12;

/// Widgetbook pinned overlay alpha (pressed / focused).
const double kMd3eComicCatalogPinnedOverlayAlphaStrong = 0.12;

/// Widgetbook pinned overlay alpha (hover / drag).
const double kMd3eComicCatalogPinnedOverlayAlphaLight = 0.08;

/// Resting shadow for catalog tiles ([M3EElevation.level1], aligned with design-system Card).
const double kMd3eComicCatalogCardRestingElevation = M3EElevation.level1;

/// Catalog comic surface: elevated tonal [M3ECard] shared by card and list layouts.
class Md3eComicCatalogCardShell extends StatelessWidget {
  const Md3eComicCatalogCardShell({
    super.key,
    required this.child,
    required this.enabled,
    required this.trackHover,
    this.onPressed,
    this.semanticLabel,
    this.dragged = false,
    this.pinnedOverlayAlpha = 0,
    this.height,
    this.width,
  });

  final Widget child;
  final bool enabled;
  final bool trackHover;
  final VoidCallback? onPressed;
  final String? semanticLabel;
  final bool dragged;
  final double pinnedOverlayAlpha;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(kMd3eComicCardRadius);

    Widget content = child;
    if (pinnedOverlayAlpha > 0) {
      final bool reduceMotion = Md3eMotion.reduceMotionOf(context);
      final Duration motionDuration = Md3eMotion.motionDurationOf(
        context,
        Md3eMotion.durationShort,
      );
      final Curve curve = Md3eMotion.curveForStateEnter(
        reduceMotion: reduceMotion,
      );
      content = ClipRRect(
        borderRadius: radius,
        child: Stack(
          fit: StackFit.passthrough,
          children: <Widget>[
            child,
            Positioned.fill(
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween<double>(end: pinnedOverlayAlpha),
                  duration: motionDuration,
                  curve: curve,
                  builder: (
                    BuildContext context,
                    double alpha,
                    Widget? child,
                  ) {
                    if (alpha <= 0) {
                      return const SizedBox.shrink();
                    }
                    return ColoredBox(
                      color: scheme.onSurface.withValues(alpha: alpha),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      );
    }

    final Widget card = M3ECard(
      variant: M3ECardVariant.elevated,
      color: scheme.surfaceContainerLow,
      padding: EdgeInsets.zero,
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      enabled: enabled,
      dragged: dragged,
      trackHover: trackHover,
      onPressed: onPressed,
      semanticLabel: semanticLabel,
      child: content,
    );

    if (height == null && width == null) {
      return card;
    }
    return SizedBox(
      height: height,
      width: width ?? double.infinity,
      child: card,
    );
  }
}

/// Title style shared by catalog card and list item.
TextStyle md3eComicCatalogTitleStyle(M3ETypeScale type, M3EColorScheme scheme) {
  return type.titleSmall.copyWith(
    fontWeight: FontWeight.w600,
    color: scheme.onSurface,
  );
}

/// Subtitle / meta style shared by catalog card and list item.
TextStyle md3eComicCatalogSubtitleStyle(
  M3ETypeScale type,
  M3EColorScheme scheme,
) {
  return type.labelSmall.copyWith(color: scheme.onSurfaceVariant);
}
