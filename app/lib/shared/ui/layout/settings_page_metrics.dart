import 'package:hentai_library/design-system/design_system.dart';

/// Layout tokens for [SettingsLayout] (Kazumi-inspired list–detail).
/// 页面留白与标题见 PageLayoutSpec。
abstract final class SettingsPageMetrics {
  static const double masterPaneWidth = 280;
  static const double paneGap = 24;
  static const double detailContentMaxWidth = 880;
  static const double detailListMaxWidth = 1000;

  static bool useListDetail(double width) {
    return width >= Breakpoints.expanded;
  }
}
