import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 详情页封面占位（2:3，轻阴影）。
class AppComicDetailCover extends StatelessWidget {
  const AppComicDetailCover({super.key, this.child, this.width});

  final Widget? child;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final double resolvedWidth =
        width ?? ComicDetailPageMetrics.coverWidth(windowSizeClassOf(context));
    final double height =
        resolvedWidth / ComicDetailPageMetrics.coverAspectRatio;
    final BorderRadius radius = BorderRadius.circular(
      ComicDetailPageMetrics.coverCornerRadius,
    );

    // 白底与列表 letterbox 封面一致，避免 Hero 落地时露出 surfaceContainer 闪一下。
    return Material(
      elevation: M3EElevation.level1,
      shadowColor: scheme.shadow.withValues(alpha: 0.18),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      color: Colors.white,
      child: SizedBox(
        width: resolvedWidth,
        height: height,
        child:
            child ??
            Icon(
              Icons.image_outlined,
              size: 48,
              color: scheme.onSurfaceVariant,
            ),
      ),
    );
  }
}
