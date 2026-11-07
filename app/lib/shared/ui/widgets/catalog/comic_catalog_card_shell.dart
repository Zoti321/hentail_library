import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/motion/spring_value.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Shared corner radius for catalog grid [ComicCard] and list [ComicListItem].
const double kComicCardRadius = 12;

/// Horizontal inset for text blocks (card info + list row).
const double kComicCatalogContentHorizontalPadding = 12;

/// Widgetbook pinned overlay alpha (pressed / focused).
const double kComicCatalogPinnedOverlayAlphaStrong = 0.12;

/// Widgetbook pinned overlay alpha (hover / drag).
const double kComicCatalogPinnedOverlayAlphaLight = 0.08;

/// Catalog comic surface: flat filled [M3ECard] (`surfaceContainer`, no shadow) shared by card and list layouts.
class ComicCatalogCardShell extends StatelessWidget {
  const ComicCatalogCardShell({
    super.key,
    required this.child,
    required this.enabled,
    required this.trackHover,
    this.onPressed,
    this.semanticLabel,
    this.dragged = false,
    this.selected = false,
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

  /// 选择模式下已选中：卡片底色切换为 primaryContainer。
  final bool selected;
  final double pinnedOverlayAlpha;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final BorderRadius radius = BorderRadius.circular(kComicCardRadius);

    // 遮罩层常驻于树中，使 0 ↔ 非 0 的变化能走弹簧补间（而不是重新挂载直接出现）。
    // 圆角由 M3ECard 的 clipBehavior 统一裁剪。
    final Widget content = Stack(
      fit: StackFit.passthrough,
      children: <Widget>[
        child,
        Positioned.fill(
          child: IgnorePointer(
            child: SpringValue(
              value: pinnedOverlayAlpha,
              builder: (BuildContext context, double alpha, Widget? child) {
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
    );

    final Widget card = M3ECard(
      variant: M3ECardVariant.filled,
      color: selected ? scheme.primaryContainer : scheme.surfaceContainer,
      elevation: M3EElevation.level0,
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
TextStyle comicCatalogTitleStyle(M3ETypeScale type, M3EColorScheme scheme) {
  return type.titleSmall.copyWith(
    fontWeight: FontWeight.w600,
    color: scheme.onSurface,
  );
}

/// Subtitle / meta style shared by catalog card and list item.
TextStyle comicCatalogSubtitleStyle(M3ETypeScale type, M3EColorScheme scheme) {
  return type.labelSmall.copyWith(color: scheme.onSurfaceVariant);
}
