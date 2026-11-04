import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 首页 Kazumo 风导航卡填色（MD3 *Container，与全库统计 bento 同系）。
abstract final class Md3eHomeShortcutCardColors {
  /// 与上方漫画 [primaryContainer] hero 区分。
  static Color historyBackground(M3EColorScheme scheme) =>
      scheme.tertiaryContainer;

  static Color historyForeground(M3EColorScheme scheme) =>
      scheme.onTertiaryContainer;

  static Color trashBackground(M3EColorScheme scheme) =>
      scheme.secondaryContainer;

  static Color trashForeground(M3EColorScheme scheme) =>
      scheme.onSecondaryContainer;
}
