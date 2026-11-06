import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/pinned_toolbar_chrome_metrics.dart';

/// 粘滞页头内工具行（固定行高；内边距与背景由 [PageHeaderDelegate] 提供）。
class PinnedToolbarChrome extends StatelessWidget {
  const PinnedToolbarChrome({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: PinnedToolbarChromeMetrics.toolbarRowHeight,
      child: child,
    );
  }
}
