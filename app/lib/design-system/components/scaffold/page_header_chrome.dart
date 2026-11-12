import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/layout/page_layout_spec.dart';
import 'package:hentai_library/design-system/layout/pinned_toolbar_chrome_metrics.dart';
import 'package:hentai_library/design-system/theme/color/desktop_shell_surfaces.dart';
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
