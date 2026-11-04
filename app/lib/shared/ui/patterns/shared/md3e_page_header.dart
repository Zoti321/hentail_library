import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/page_layout_spec.dart';
import 'package:hentai_library/shared/ui/layout/pinned_toolbar_chrome_metrics.dart';
import 'package:hentai_library/shared/ui/shell/desktop_shell_surfaces.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 页头画布与内边距（水平留白、上下内边距由 [Md3ePageLayoutSpec] 决定）。
///
/// 粘滞模式下滚动后以阴影与正文分块；非粘滞模式始终 level0。
class Md3ePageHeaderChrome extends StatelessWidget {
  const Md3ePageHeaderChrome({
    super.key,
    required this.layout,
    required this.child,
    this.elevated = false,
  });

  final Md3ePageLayoutSpec layout;
  final Widget child;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final Color canvas = md3eLabBrowseCanvasColor(scheme);

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
}

/// 粘滞页头 [SliverPersistentHeader] 的 delegate（由 [Md3ePageHeaderSliver] 在 [pinned] 为 true 时使用）。
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
    final bool elevated = shrinkOffset > 0 || overlapsContent;

    return Md3ePageHeaderChrome(
      layout: layout,
      elevated: elevated,
      child: child,
    );
  }

  @override
  bool shouldRebuild(covariant Md3ePageHeaderDelegate oldDelegate) {
    return oldDelegate.layout != layout || oldDelegate.child != child;
  }
}

/// 页头 Sliver：[pinned] 为 true（默认）时粘滞顶栏；为 false 时随列表滚出视口。
class Md3ePageHeaderSliver extends StatelessWidget {
  const Md3ePageHeaderSliver({
    super.key,
    required this.layout,
    required this.child,
    this.pinned = true,
  });

  final Md3ePageLayoutSpec layout;
  final Widget child;
  final bool pinned;

  @override
  Widget build(BuildContext context) {
    if (pinned) {
      return SliverPersistentHeader(
        pinned: true,
        delegate: Md3ePageHeaderDelegate(layout: layout, child: child),
      );
    }
    return SliverToBoxAdapter(
      child: Md3ePageHeaderChrome(layout: layout, child: child),
    );
  }
}
