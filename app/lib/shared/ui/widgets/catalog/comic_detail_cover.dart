import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/comic_detail_page_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/element/image/cover_letterbox.dart';
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
    final BorderRadius radius = const BorderRadius.all(
      Radius.circular(ComicDetailPageMetrics.coverCornerRadius),
    );

    // 与卡片 letterbox token 一致，避免 Hero 落地时底色跳变。
    return Material(
      elevation: M3EElevation.level1,
      shadowColor: scheme.shadow.withValues(alpha: 0.18),
      borderRadius: radius,
      clipBehavior: Clip.antiAlias,
      color: coverLetterboxColor(context),
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
