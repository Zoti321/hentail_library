import 'package:flutter/material.dart';

/// Settle delay before restoring sharp filter quality after scroll stops.
const Duration kReaderFilterQualitySettleDelay = Duration(milliseconds: 120);

/// Scroll/idle filter quality for reader page images (P2-1).
FilterQuality readerImageFilterQuality({required bool isScrolling}) {
  return isScrolling ? FilterQuality.medium : FilterQuality.high;
}
