import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/layout/reader_chrome_metrics.dart';

/// 顶/底 chrome 显隐：复用 [SpringReveal]，仅切换弹簧与滑动方向。
class ReaderChromeReveal extends StatelessWidget {
  const ReaderChromeReveal({
    super.key,
    required this.visible,
    required this.top,
    required this.child,
  });

  final bool visible;
  final bool top;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final double slide = ReaderChromeMetrics.hideSlidePx;
    return SpringReveal(
      visible: visible,
      motion: LabMotion.readerChromeReveal,
      hiddenOffset: Offset(0, top ? -slide : slide),
      child: child,
    );
  }
}
