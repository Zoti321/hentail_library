part of 'named_facet_management_panel.dart';

// 合并选择（批量合并）模式：目标 chip 绿色、待合并来源红色，以及点击分发（#312）。

/// 合并选择对 chip 样式的影响：目标为成功色，来源为错误色，其余不着色。
({Color? fill, Color? border}) _mergeSelectionColors(
  HentaiColorScheme h, {
  required bool isMergeTarget,
  required bool isMergeSource,
}) {
  if (isMergeTarget) {
    return (fill: h.success.withValues(alpha: 0.22), border: h.success);
  }
  if (isMergeSource) {
    return (fill: h.error.withValues(alpha: 0.22), border: h.error);
  }
  return (fill: null, border: null);
}

/// 合并选择模式下点击 chip：点击目标则退出选择，点击其他则加入来源。
void _onMergeChipTap({
  required String name,
  required bool isMergeTarget,
  required VoidCallback? onExit,
  required ValueChanged<String>? onSource,
}) {
  if (isMergeTarget) {
    onExit?.call();
  } else {
    onSource?.call(name);
  }
}
