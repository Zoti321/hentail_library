import 'package:flutter/widgets.dart';
import 'package:hentai_library/md3e/theme/md3e_theme.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

TextStyle md3eLabTextStyle(M3EThemeData theme, TextStyle base) {
  return base.copyWith(fontFamily: kMd3eAppFontFamily);
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
