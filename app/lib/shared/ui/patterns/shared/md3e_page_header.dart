import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/layout/pinned_toolbar_chrome_metrics.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 粘滞页头：统一画布底色、上下内边距与水平留白由 [Md3ePageLayoutSpec] 决定；
/// 滚动后以阴影与正文分块。
class Md3ePageHeaderDelegate extends SliverPersistentHeaderDelegate {
  Md3ePageHeaderDelegate({required this.layout, required this.child});

  /// 当前页面布局规格（水平留白、上下内边距、高度）。
  final Md3ePageLayoutSpec layout;

  /// 工具行（通常为 [Md3ePinnedToolbarChrome]）。
  final Widget child;

  @override
  double get minExtent => layout.pinnedHeaderExtent;

  @override
  double get maxExtent => layout.pinnedHeaderExtent;

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
          horizontal: layout.horizontalInset,
          vertical: layout.headerVerticalInset,
        ),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant Md3ePageHeaderDelegate oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.child != child;
  }
}
