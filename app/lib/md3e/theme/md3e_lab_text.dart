import 'package:flutter/widgets.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

TextStyle md3eLabTextStyle(M3EThemeData theme, TextStyle base) {
  return base.copyWith(fontFamily: kMd3eAppFontFamily);
}

/// 与 [M3EButton] 默认 label 字号一致，并强制 Lab 字体（ButtonStyle 会覆盖 label Text）。
TextStyle md3eLabButtonLabelStyle(
  M3EThemeData theme,
  M3EButtonSize size,
) {
  final M3ETypeScale type = theme.typeScale;
  final TextStyle base = switch (size.name) {
    'xs' => type.labelSmall,
    'sm' => type.labelMedium,
    'md' => type.labelLarge,
    'lg' => type.titleMedium,
    'xl' => type.titleLarge,
    _ => type.labelLarge,
  };
  return md3eLabTextStyle(theme, base);
}

/// M3E 按钮 label 等需显式挂 Lab 字体（M3E typeScale 未必带 fontFamily）。
Widget md3eLabText(
  M3EThemeData theme,
  String data, {
  TextStyle? style,
}) {
  return Text(
    data,
    style: md3eLabTextStyle(theme, style ?? const TextStyle()),
  );
}
