import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/reader_chrome_metrics.dart';

/// 旧名兼容：宽度算法已迁至 [Md3eReaderChromeMetrics.chromeContentMaxWidth]。
abstract final class Md3eReaderFloatingPanel {
  static double targetBarWidth(BuildContext context) {
    return Md3eReaderChromeMetrics.chromeContentMaxWidth(
      MediaQuery.sizeOf(context).width,
    );
  }
}
