/// 响应式布局断点（与 [docs/agents/ui-style.md] 一致）。
abstract final class AppLayoutBreakpoints {
  /// 窄屏：抽屉导航、单列布局。
  static const double compact = 600;

  /// 中屏：折叠侧栏图标轨。
  static const double medium = 1024;

  static bool isCompact(double width) => width < compact;

  static bool isMedium(double width) => width >= compact && width < medium;

  static bool isExpanded(double width) => width >= medium;
}
