import 'dart:io';
import 'dart:ui' show FlutterView, PlatformDispatcher;

import 'package:flutter/widgets.dart';

enum ImageQualityTier { low, medium, high }

class ImageQualityPolicy {
  const ImageQualityPolicy({
    required this.tier,
    required this.decodeScale,
    required this.coverDecodeMaxWidth,
    required this.readerDecodeMaxWidth,
    required this.readerPrecacheNeighborCount,
    required this.imageCacheMaxEntries,
    required this.imageCacheMaxBytes,
  });

  final ImageQualityTier tier;
  final double decodeScale;
  final int coverDecodeMaxWidth;
  final int readerDecodeMaxWidth;
  final int readerPrecacheNeighborCount;
  final int imageCacheMaxEntries;
  final int imageCacheMaxBytes;

  static ImageQualityPolicy current = const ImageQualityPolicy(
    tier: ImageQualityTier.medium,
    decodeScale: 1.0,
    coverDecodeMaxWidth: 1024,
    readerDecodeMaxWidth: 2560,
    readerPrecacheNeighborCount: 4,
    imageCacheMaxEntries: 600,
    imageCacheMaxBytes: 256 * 1024 * 1024,
  );

  static ImageQualityPolicy resolveAuto({
    required int cpuCores,
    required double pixelLoadInMegaPixels,
  }) {
    if (cpuCores <= 4 || pixelLoadInMegaPixels > 8.3) {
      return const ImageQualityPolicy(
        tier: ImageQualityTier.low,
        decodeScale: 0.9,
        coverDecodeMaxWidth: 768,
        readerDecodeMaxWidth: 1600,
        readerPrecacheNeighborCount: 2,
        imageCacheMaxEntries: 300,
        imageCacheMaxBytes: 128 * 1024 * 1024,
      );
    }
    if (cpuCores >= 8 && pixelLoadInMegaPixels <= 5.0) {
      return const ImageQualityPolicy(
        tier: ImageQualityTier.high,
        decodeScale: 1.2,
        coverDecodeMaxWidth: 1600,
        readerDecodeMaxWidth: 4096,
        readerPrecacheNeighborCount: 6,
        imageCacheMaxEntries: 1000,
        imageCacheMaxBytes: 512 * 1024 * 1024,
      );
    }
    return const ImageQualityPolicy(
      tier: ImageQualityTier.medium,
      decodeScale: 1.0,
      coverDecodeMaxWidth: 1024,
      readerDecodeMaxWidth: 2560,
      readerPrecacheNeighborCount: 4,
      imageCacheMaxEntries: 600,
      imageCacheMaxBytes: 256 * 1024 * 1024,
    );
  }
}

ImageQualityPolicy configureImageQualityPolicy() {
  final PlatformDispatcher dispatcher = WidgetsBinding
      .instance
      .platformDispatcher;
  final FlutterView? primaryView = dispatcher.views.isNotEmpty
      ? dispatcher.views.first
      : null;
  final double pixelLoadInMegaPixels = primaryView == null
      ? 2.0
      : (primaryView.physicalSize.width * primaryView.physicalSize.height) /
            1000000.0;
  final int cpuCores = Platform.numberOfProcessors;
  final ImageQualityPolicy resolved = ImageQualityPolicy.resolveAuto(
    cpuCores: cpuCores,
    pixelLoadInMegaPixels: pixelLoadInMegaPixels,
  );
  ImageQualityPolicy.current = resolved;
  return resolved;
}
