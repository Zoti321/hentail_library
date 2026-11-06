import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/widgets/pagination/pagination_page_window.dart';

/// Layout constants for [Pagination].
abstract final class PaginationMetrics {
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

  static PaginationSiblingConfig siblingConfigFor(
    WindowSizeClass sizeClass,
  ) {
    if (sizeClass.index < WindowSizeClass.expanded.index) {
      return PaginationSiblingConfig.compact;
    }
    return PaginationSiblingConfig.muiDefault;
  }

  static int fixedPageSlotCount(WindowSizeClass sizeClass) {
    return paginationFixedPageSlotCount(siblingConfigFor(sizeClass));
  }

  /// Stable page-number strip width (MUI-style fixed slots).
  static double pageNumberStripWidth(WindowSizeClass sizeClass) {
    return pageButtonSlotWidth * fixedPageSlotCount(sizeClass);
  }

  static const double compactPageSummaryMinWidth = 72;

  /// [M3EIconButtonSize.sm] interactive footprint.
  static const double standardNavIconSlot = 48;

  /// Minimum width needed to render [PaginationStandard] without clipping.
  static double standardBarMinWidth(WindowSizeClass sizeClass) {
    return horizontalPaddingStandard * 2 +
        standardNavIconSlot * 4 +
        pageNumberStripWidth(sizeClass);
  }
}
