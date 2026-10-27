import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_comic_detail_page_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 详情页封面占位（2:3，轻阴影）。
class Md3eComicDetailCover extends StatelessWidget {
  const Md3eComicDetailCover({
    super.key,
    this.child,
    this.width,
  });

  final Widget? child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final double resolvedWidth =
        width ??
        Md3eComicDetailPageMetrics.coverWidth(md3eWindowSizeClassOf(context));
    final double height =
        resolvedWidth / Md3eComicDetailPageMetrics.coverAspectRatio;
    final BorderRadius radius = BorderRadius.circular(
      Md3eComicDetailPageMetrics.coverCornerRadius,
    );

    return Material(
      elevation: M3EElevation.level1,
      shadowColor: scheme.shadow.withValues(alpha: 0.18),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      color: scheme.surfaceContainerHighest,
      child: SizedBox(
        width: resolvedWidth,
        height: height,
        child: child ??
            Icon(
              Icons.image_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
