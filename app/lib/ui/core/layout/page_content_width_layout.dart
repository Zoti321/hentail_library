import 'dart:math' as math;

import 'package:flutter/material.dart';

/// expanded 档内容区最大宽度；与首页/历史/管理/设置/选中路径页对齐。
const double kPageContentMaxWidth = 1280;

double pageInnerContentMaxWidth({
  required double viewportWidth,
  required double horizontalPadding,
  required bool capAtMaxWidth,
}) {
  final double paddedWidth = viewportWidth - horizontalPadding * 2;
  if (capAtMaxWidth) {
    return math.min(paddedWidth, kPageContentMaxWidth);
  }
  return paddedWidth;
}

/// 与 [PageContentWidthAlign] 等价的左侧（或对称）inset，供 Sliver 等场景使用。
double pageContentAlignedHorizontalInset({
  required double viewportWidth,
  required double horizontalPadding,
  required double maxWidth,
}) {
  final double paddedWidth = viewportWidth - horizontalPadding * 2;
  final double centeredInset = paddedWidth > maxWidth
      ? (paddedWidth - maxWidth) / 2
      : 0;
  return horizontalPadding + centeredInset;
}

/// 页面 header/body 共用：水平 padding + 居中 maxWidth 约束。
class PageContentWidthAlign extends StatelessWidget {
  const PageContentWidthAlign({
    super.key,
    required this.horizontalPadding,
    required this.maxWidth,
    required this.child,
    this.alignment = Alignment.topCenter,
  });

  final double horizontalPadding;
  final double maxWidth;
  final Widget child;
  final AlignmentGeometry alignment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Align(
        alignment: alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: child,
        ),
      ),
    );
  }
}
