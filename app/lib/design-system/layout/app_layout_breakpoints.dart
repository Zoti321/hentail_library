/// 响应式布局断点（原与 design-system MASTER 对齐，该文档已于 2026-11-01 移除）。
abstract final class AppLayoutBreakpoints {
  /// 桌面窗口最小宽度（逻辑像素），对齐常见小屏手机 viewport，且低于 [compact]。
  static const double minWindowWidth = 360;

  /// 桌面窗口最小高度（逻辑像素）；宽度优先对齐真机，高度保留垂直压窗空间。
  static const double minWindowHeight = 480;

  /// 窄屏：底部导航、单列布局。
  static const double compact = 600;

  /// 中屏：底部导航；≥ 此值起用 NavigationRail（M3 expanded 下限 840）。
  static const double medium = 840;

  static bool isCompact(double width) => width < compact;

  static bool isMedium(double width) => width >= compact && width < medium;

  static bool isExpanded(double width) => width >= medium;
}
