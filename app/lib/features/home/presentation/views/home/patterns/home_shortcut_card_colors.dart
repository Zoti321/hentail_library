import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 首页 Kazumo 风导航卡填色（MD3 *Container，与全库统计 bento 同系）。
///
/// 不用 `tertiaryContainer`：紫罗兰 seed 下 fidelity tertiary 偏芥末黄，与品牌紫不协调。
abstract final class HomeShortcutCardColors {
  /// 柔和 surface 阶，介于漫画 [primaryContainer] 与垃圾桶 [secondaryContainer] 之间。
  static Color historyBackground(M3EColorScheme scheme) =>
      scheme.surfaceContainerHigh;

  static Color historyForeground(M3EColorScheme scheme) => scheme.onSurface;

  static Color trashBackground(M3EColorScheme scheme) =>
      scheme.secondaryContainer;

  static Color trashForeground(M3EColorScheme scheme) =>
      scheme.onSecondaryContainer;
}
