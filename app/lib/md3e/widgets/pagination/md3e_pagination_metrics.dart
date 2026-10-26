import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/widgets/pagination/md3e_pagination_page_window.dart';

/// Layout constants for [Md3ePagination].
abstract final class Md3ePaginationMetrics {
  static const double pageButtonVisualSize = 40;
  static const double iconSize = 20;
  static const double horizontalPaddingCompact = 16;
  static const double horizontalPaddingStandard = 12;
  static const double compactButtonMinHeight = 48;

  /// Compact prev/next [M3EIconButtonSize.md] (larger than standard strip).
  static const double compactNavIconSize = 24;

  static const double compactNavIconSlot = 48;
  static const double gapBetweenPageButtons = 2;

  /// Fixed width per page / ellipsis slot (padding included).
  static double get pageButtonSlotWidth =>
      pageButtonVisualSize + gapBetweenPageButtons * 2;

  static Md3ePaginationSiblingConfig siblingConfigFor(
    Md3eWindowSizeClass sizeClass,
  ) {
    if (sizeClass.index < Md3eWindowSizeClass.expanded.index) {
      return Md3ePaginationSiblingConfig.compact;
    }
    return Md3ePaginationSiblingConfig.muiDefault;
  }

  static int fixedPageSlotCount(Md3eWindowSizeClass sizeClass) {
    return md3ePaginationFixedPageSlotCount(siblingConfigFor(sizeClass));
  }

  /// Stable page-number strip width (MUI-style fixed slots).
  static double pageNumberStripWidth(Md3eWindowSizeClass sizeClass) {
    return pageButtonSlotWidth * fixedPageSlotCount(sizeClass);
  }

  static const double compactPageSummaryMinWidth = 72;

  /// [M3EIconButtonSize.sm] interactive footprint.
  static const double standardNavIconSlot = 48;

  /// Minimum width needed to render [Md3ePaginationStandard] without clipping.
  static double standardBarMinWidth(Md3eWindowSizeClass sizeClass) {
    return horizontalPaddingStandard * 2 +
        standardNavIconSlot * 4 +
        pageNumberStripWidth(sizeClass);
  }
}
