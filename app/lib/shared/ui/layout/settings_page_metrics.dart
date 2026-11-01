import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';

/// Layout tokens for [Md3eSettingsPage] (Kazumi-inspired list–detail).
abstract final class Md3eSettingsPageMetrics {
  static const double masterPaneWidth = 280;
  static const double paneGap = 24;
  static const double detailContentMaxWidth = 880;
  static const double detailListMaxWidth = 1000;

  static double contentHorizontalPadding(Md3eWindowSizeClass sizeClass) {
    return Md3eLibraryPageHeaderMetrics.contentHorizontalPadding(sizeClass);
  }

  static bool useListDetail(double width) {
    return width >= Md3eBreakpoints.expanded;
  }
}
