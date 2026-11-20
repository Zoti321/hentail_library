import 'dart:math' as math;

/// Max longest edge (px) for Read session page-image decode under
/// **Page image fidelity** oversized safety (#591 / ADR-0065).
const int kReaderPageDecodeMaxEdge = 8192;

/// Decode target for a Read session page bitmap.
///
/// When [capped] is false, [cacheWidth] / [cacheHeight] are null so the
/// decoder keeps source resolution (no viewport downdecode).
typedef PageDecodeSize = ({int? cacheWidth, int? cacheHeight, bool capped});

/// Maps source pixel size to a decode target under [maxEdge].
///
/// If `max(sourceWidth, sourceHeight) <= maxEdge`, returns uncapped nulls.
/// Otherwise scales so the longest edge equals [maxEdge].
PageDecodeSize pageDecodeSizeForSource({
  required int sourceWidth,
  required int sourceHeight,
  int maxEdge = kReaderPageDecodeMaxEdge,
}) {
  if (sourceWidth <= 0 || sourceHeight <= 0 || maxEdge <= 0) {
    return (cacheWidth: null, cacheHeight: null, capped: false);
  }
  final int longest = math.max(sourceWidth, sourceHeight);
  if (longest <= maxEdge) {
    return (cacheWidth: null, cacheHeight: null, capped: false);
  }
  final double scale = maxEdge / longest;
  return (
    cacheWidth: math.max(1, (sourceWidth * scale).round()),
    cacheHeight: math.max(1, (sourceHeight * scale).round()),
    capped: true,
  );
}
