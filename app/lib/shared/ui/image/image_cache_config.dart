import 'package:flutter/painting.dart';
import 'package:flutter/widgets.dart';

/// 全局 [ImageCache] 最大条目数。
const int kGlobalImageCacheMaxEntries = 600;

/// 全局 [ImageCache] 最大字节数。
const int kGlobalImageCacheMaxBytes = 256 * 1024 * 1024;

void configureGlobalImageCache() {
  final ImageCache imageCache = PaintingBinding.instance.imageCache;
  imageCache.maximumSize = kGlobalImageCacheMaxEntries;
  imageCache.maximumSizeBytes = kGlobalImageCacheMaxBytes;
}
