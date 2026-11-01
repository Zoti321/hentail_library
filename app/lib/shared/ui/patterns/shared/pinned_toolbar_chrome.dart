import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/pinned_toolbar_chrome_metrics.dart';

/// 粘滞页头内工具行（固定行高；内边距与背景由 [Md3ePageHeaderDelegate] 提供）。
class Md3ePinnedToolbarChrome extends StatelessWidget {
  const Md3ePinnedToolbarChrome({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: Md3ePinnedToolbarChromeMetrics.toolbarRowHeight,
      child: child,
    );
  }
}
