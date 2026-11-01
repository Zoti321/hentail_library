import 'package:hentai_library/shared/ui/layout/breakpoints.dart';

/// Layout tokens for [Md3eSettingsPage] (Kazumi-inspired list–detail).
/// 页面留白与标题见 Md3ePageLayoutSpec。
abstract final class Md3eSettingsPageMetrics {
  static const double masterPaneWidth = 280;
  static const double paneGap = 24;
  static const double detailContentMaxWidth = 880;
  static const double detailListMaxWidth = 1000;

  static bool useListDetail(double width) {
    return width >= Md3eBreakpoints.expanded;
  }
}
