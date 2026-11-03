import 'package:flutter/material.dart';

/// 元数据编辑表单内滚动：不绘制 Material scrollbar（含 Windows 悬停轨道）。
final class Md3eMetadataEditScrollBehavior extends MaterialScrollBehavior {
  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
