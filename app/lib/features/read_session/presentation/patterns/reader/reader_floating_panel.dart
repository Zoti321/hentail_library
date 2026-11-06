import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/reader_chrome_metrics.dart';

/// 旧名兼容：宽度算法已迁至 [ReaderChromeMetrics.chromeContentMaxWidth]。
abstract final class ReaderFloatingPanel {
  static double targetBarWidth(BuildContext context) {
    return ReaderChromeMetrics.chromeContentMaxWidth(
      MediaQuery.sizeOf(context).width,
    );
  }
}
