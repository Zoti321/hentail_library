import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// Logical width/height pair for [ResizeImage] / ExtendedImage decode limits.
typedef ImageDecodeCacheSize = ({int? cacheWidth, int? cacheHeight});

/// Decode pixel size from layout logical dimensions and [devicePixelRatio].
ImageDecodeCacheSize decodeCacheSizeForLogicalSize({
  required double logicalWidth,
  required double logicalHeight,
  required double devicePixelRatio,
}) {
  if (logicalWidth <= 0 || logicalHeight <= 0 || devicePixelRatio <= 0) {
    return (cacheWidth: null, cacheHeight: null);
  }
  return (
    cacheWidth: math.max(1, (logicalWidth * devicePixelRatio).ceil()),
    cacheHeight: math.max(1, (logicalHeight * devicePixelRatio).ceil()),
  );
}

/// Decode limits from the current [BuildContext] and logical layout size.
ImageDecodeCacheSize decodeCacheSizeForContext(
  BuildContext context, {
  required double logicalWidth,
  required double logicalHeight,
}) {
  return decodeCacheSizeForLogicalSize(
    logicalWidth: logicalWidth,
    logicalHeight: logicalHeight,
    devicePixelRatio: MediaQuery.devicePixelRatioOf(context),
  );
}
