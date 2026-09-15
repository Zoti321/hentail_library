import 'dart:math' as math;

import 'package:hentai_library/ui/core/layout/detail_meta_chip_row_layout.dart';

/// Tag facet chip band: wrap up to three rows before horizontal scroll.
const int kDetailMetaChipBandMaxRowsTag = 3;

/// Character facet chip band: wrap up to two rows before horizontal scroll.
const int kDetailMetaChipBandMaxRowsCharacter = 2;

/// Author / Parody (and any single-row) facet chip band.
const int kDetailMetaChipBandMaxRowsSingle = 1;

/// Result of packing chips into a max-row wrap band.
typedef DetailMetaChipBandLayout = ({
  double contentWidth,
  int usedRows,
  double bandHeight,
});

/// Counts wrap rows for [chipWidths] flowing left-to-right within [maxWidth].
int countDetailMetaChipBandRows({
  required List<double> chipWidths,
  required double maxWidth,
  required double spacing,
}) {
  if (chipWidths.isEmpty) {
    return 0;
  }
  var rows = 1;
  var x = 0.0;
  for (final double w in chipWidths) {
    if (x == 0) {
      x = w;
      continue;
    }
    if (x + spacing + w <= maxWidth + 1e-6) {
      x += spacing + w;
    } else {
      rows += 1;
      x = w;
    }
  }
  return rows;
}

double detailMetaChipBandHeight({
  required int usedRows,
  required double rowHeight,
  required double runSpacing,
}) {
  if (usedRows <= 0) {
    return 0;
  }
  return usedRows * rowHeight + (usedRows - 1) * runSpacing;
}

/// Packs chips into at most [maxRows] wrap rows at [availableWidth].
///
/// When chips fit, [DetailMetaChipBandLayout.contentWidth] equals
/// [availableWidth] and height follows used rows (no empty reserved rows).
/// When they overflow [maxRows], content width grows so wrapping fits the
/// cap and the band is expected to scroll horizontally.
DetailMetaChipBandLayout layoutDetailMetaChipBand({
  required List<double> chipWidths,
  required double availableWidth,
  required int maxRows,
  required double spacing,
  required double runSpacing,
  double rowHeight = kDetailMetaChipRowHeight,
}) {
  assert(maxRows >= 1, 'maxRows must be >= 1');
  if (chipWidths.isEmpty) {
    return (contentWidth: 0, usedRows: 0, bandHeight: 0);
  }

  final double safeAvailable = math.max(availableWidth, 0);
  final int rowsAtAvailable = countDetailMetaChipBandRows(
    chipWidths: chipWidths,
    maxWidth: safeAvailable,
    spacing: spacing,
  );
  if (rowsAtAvailable <= maxRows) {
    return (
      contentWidth: safeAvailable,
      usedRows: rowsAtAvailable,
      bandHeight: detailMetaChipBandHeight(
        usedRows: rowsAtAvailable,
        rowHeight: rowHeight,
        runSpacing: runSpacing,
      ),
    );
  }

  final double widest = chipWidths.reduce(math.max);
  final double oneRowWidth =
      chipWidths.fold<double>(0, (double sum, double w) => sum + w) +
      spacing * (chipWidths.length - 1);

  var lo = widest;
  var hi = math.max(oneRowWidth, widest);
  for (var i = 0; i < 24; i++) {
    final double mid = (lo + hi) / 2;
    if (countDetailMetaChipBandRows(
          chipWidths: chipWidths,
          maxWidth: mid,
          spacing: spacing,
        ) <=
        maxRows) {
      hi = mid;
    } else {
      lo = mid;
    }
  }

  final int usedRows = countDetailMetaChipBandRows(
    chipWidths: chipWidths,
    maxWidth: hi,
    spacing: spacing,
  );
  return (
    contentWidth: hi,
    usedRows: usedRows,
    bandHeight: detailMetaChipBandHeight(
      usedRows: usedRows,
      rowHeight: rowHeight,
      runSpacing: runSpacing,
    ),
  );
}
