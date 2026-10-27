import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/layout/md3e_pinned_toolbar_chrome_metrics.dart';

/// 粘滞顶栏内工具行容器（内边距与行高；阴影由 [Md3eLibraryPinnedHeaderDelegate] 绘制）。
class Md3ePinnedToolbarChrome extends StatelessWidget {
  const Md3ePinnedToolbarChrome({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final Md3eWindowSizeClass sizeClass = md3eWindowSizeClassOf(context);
    return Padding(
      padding: EdgeInsets.only(
        top: Md3ePinnedToolbarChromeMetrics.topPadding(sizeClass),
        bottom: Md3ePinnedToolbarChromeMetrics.bottomPadding(sizeClass),
      ),
      child: SizedBox(
        height: Md3ePinnedToolbarChromeMetrics.toolbarRowHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Md3ePinnedToolbarChromeMetrics.innerHorizontalInset,
          ),
          child: child,
        ),
      ),
    );
  }
}
