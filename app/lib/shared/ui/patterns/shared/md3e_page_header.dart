import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/pinned_toolbar_chrome_metrics.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 粘滞页头尺寸（漫画库 / 漫画详情 / 系列详情 / 阅读历史 / 垃圾桶共用）。
abstract final class Md3ePageHeaderMetrics {
  /// 内容块四边内边距相等。
  static const double inset = 12;

  static const double extent =
      inset * 2 + Md3ePinnedToolbarChromeMetrics.toolbarRowHeight;
}

/// 粘滞页头：统一画布底色、四边等距内边距；滚动后以阴影与正文分块。
class Md3ePageHeaderDelegate extends SliverPersistentHeaderDelegate {
  Md3ePageHeaderDelegate({required this.pageHorizontal, required this.child});

  /// 页面水平内边距（与正文网格一致）。
  final double pageHorizontal;

  /// 工具行（通常为 [Md3ePinnedToolbarChrome]）。
  final Widget child;

  @override
  double get minExtent => Md3ePageHeaderMetrics.extent;

  @override
  double get maxExtent => Md3ePageHeaderMetrics.extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color canvas = md3eLabBrowseCanvasColor(scheme);
    final bool elevated = shrinkOffset > 0 || overlapsContent;

    return Material(
      color: canvas,
      elevation: elevated
          ? Md3ePinnedToolbarChromeMetrics.pinnedHeaderElevation
          : M3EElevation.level0,
      shadowColor: scheme.shadow,
      surfaceTintColor: const Color(0x00000000),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: pageHorizontal,
          vertical: Md3ePageHeaderMetrics.inset,
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant Md3ePageHeaderDelegate oldDelegate) {
    return oldDelegate.pageHorizontal != pageHorizontal ||
        oldDelegate.child != child;
  }
}
