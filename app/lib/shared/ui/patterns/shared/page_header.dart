import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/pinned_toolbar_chrome_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 页头画布与内边距（水平留白、上下内边距由 [PageLayoutSpec] 决定）。
///
/// 粘滞模式下滚动后以阴影与正文分块；非粘滞模式始终 level0。
class PageHeaderChrome extends StatelessWidget {
  const PageHeaderChrome({
    super.key,
    required this.layout,
    required this.child,
    this.elevated = false,
  });

  final PageLayoutSpec layout;
  final Widget child;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color canvas = labBrowseCanvasColor(scheme);

    return Material(
      color: canvas,
      elevation: elevated
          ? PinnedToolbarChromeMetrics.pinnedHeaderElevation
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
}

/// 粘滞页头 [SliverPersistentHeader] 的 delegate（由 [PageHeaderSliver] 在 [pinned] 为 true 时使用）。
class PageHeaderDelegate extends SliverPersistentHeaderDelegate {
  PageHeaderDelegate({required this.layout, required this.child});

  /// 当前页面布局规格（水平留白、上下内边距、高度）。
  final PageLayoutSpec layout;

  /// 工具行（通常为 [PinnedToolbarChrome]）。
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
    final bool elevated = shrinkOffset > 0 || overlapsContent;

    return PageHeaderChrome(layout: layout, elevated: elevated, child: child);
  }

  @override
  bool shouldRebuild(covariant PageHeaderDelegate oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.child != child;
  }
}

/// 页头 Sliver：[pinned] 为 true（默认）时粘滞顶栏；为 false 时随列表滚出视口。
class PageHeaderSliver extends StatelessWidget {
  const PageHeaderSliver({
    super.key,
    required this.layout,
    required this.child,
    this.pinned = true,
  });

  final PageLayoutSpec layout;
  final Widget child;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    if (pinned) {
      return SliverPersistentHeader(
        pinned: true,
        delegate: PageHeaderDelegate(layout: layout, child: child),
      );
    }
    return SliverToBoxAdapter(
      child: PageHeaderChrome(layout: layout, child: child),
    );
  }
}
