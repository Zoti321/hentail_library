import 'dart:typed_data';

import 'package:flutter/material.dart';

/// Letterbox fill behind catalog/detail covers (MD3; tracks light/dark).
Color coverLetterboxColor(BuildContext context) =>
    Theme.of(context).colorScheme.surfaceContainerHighest;

/// Relative aspect-ratio delta at or below which we [BoxFit.cover] instead of
/// letterboxing. 8% ≈ thin bars on a 2:3 card.
const double kCoverSoftCropAspectTolerance = 0.08;

/// Picks cover vs contain from image vs slot aspect ratios.
BoxFit coverFitForAspects({
  required double imageAspect,
  required double boxAspect,
  double tolerance = kCoverSoftCropAspectTolerance,
}) {
  if (imageAspect <= 0 || boxAspect <= 0) {
    return BoxFit.contain;
  }
  final double delta = (imageAspect - boxAspect).abs() / boxAspect;
  return delta <= tolerance ? BoxFit.cover : BoxFit.contain;
}

/// Soft-crop [BoxFit] from known pixel size, or [BoxFit.contain] if unknown.
BoxFit coverFitForImageSize({
  required Size? imageSize,
  required double boxAspect,
  double tolerance = kCoverSoftCropAspectTolerance,
}) {
  if (imageSize == null || imageSize.height <= 0) {
    return BoxFit.contain;
  }
  return coverFitForAspects(
    imageAspect: imageSize.width / imageSize.height,
    boxAspect: boxAspect,
    tolerance: tolerance,
  );
}

/// Reads JPEG/PNG pixel size from header bytes without full decode.
///
/// Used so soft-crop [BoxFit] is known on first paint (Hero lands without a
/// post-flight contain→cover jump). Returns null if format is unsupported.
Size? peekCoverImageSize(Uint8List? bytes) {
  if (bytes == null || bytes.length < 10) {
    return null;
  }
  if (bytes[0] == 0xFF && bytes[1] == 0xD8) {
    return _peekJpegSize(bytes);
  }
  if (bytes.length >= 24 &&
      bytes[0] == 0x89 &&
      bytes[1] == 0x50 &&
      bytes[2] == 0x4E &&
      bytes[3] == 0x47) {
    return _peekPngSize(bytes);
  }
  return null;
}

Size? _peekPngSize(Uint8List bytes) {
  // IHDR is the first chunk: 8 sig + 4 len + 4 type + 4 width + 4 height.
  if (bytes.length < 24) {
    return null;
  }
  final int width =
      (bytes[16] << 24) | (bytes[17] << 16) | (bytes[18] << 8) | bytes[19];
  final int height =
      (bytes[20] << 24) | (bytes[21] << 16) | (bytes[22] << 8) | bytes[23];
  if (width <= 0 || height <= 0) {
    return null;
  }
  return Size(width.toDouble(), height.toDouble());
}

Size? _peekJpegSize(Uint8List bytes) {
  int i = 2;
  while (i + 9 < bytes.length) {
    if (bytes[i] != 0xFF) {
      i++;
      continue;
    }
    while (i < bytes.length && bytes[i] == 0xFF) {
      i++;
    }
    if (i >= bytes.length) {
      return null;
    }
    final int marker = bytes[i++];
    // Standalone markers without length.
    if (marker == 0xD8 ||
        marker == 0xD9 ||
        (marker >= 0xD0 && marker <= 0xD7)) {
      continue;
    }
    if (i + 1 >= bytes.length) {
      return null;
    }
    final int segmentLength = (bytes[i] << 8) | bytes[i + 1];
    if (segmentLength < 2 || i + segmentLength > bytes.length) {
      return null;
    }
    // SOF0..SOF3, SOF5..SOF7, SOF9..SOF11, SOF13..SOF15 (baseline/progressive).
    final bool isSof =
        (marker >= 0xC0 && marker <= 0xC3) ||
        (marker >= 0xC5 && marker <= 0xC7) ||
        (marker >= 0xC9 && marker <= 0xCB) ||
        (marker >= 0xCD && marker <= 0xCF);
    if (isSof && segmentLength >= 7 && i + 6 < bytes.length) {
      final int height = (bytes[i + 3] << 8) | bytes[i + 4];
      final int width = (bytes[i + 5] << 8) | bytes[i + 6];
      if (width > 0 && height > 0) {
        return Size(width.toDouble(), height.toDouble());
      }
      return null;
    }
    i += segmentLength;
  }
  return null;
}
