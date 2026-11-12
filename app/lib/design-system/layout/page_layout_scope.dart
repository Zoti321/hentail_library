import 'package:flutter/material.dart';
import 'package:hentai_library/design-system/layout/page_layout_spec.dart';

/// 布局规格的继承作用域，由 [PageViewport] 提供，读取方使用 [PageLayoutSpec.of]。
final class PageLayoutScope extends InheritedWidget {
  const PageLayoutScope({
    super.key,
    required this.layout,
    required super.child,
  });

  final PageLayoutSpec layout;

  @override
  bool updateShouldNotify(PageLayoutScope oldWidget) {
    return oldWidget.layout != layout;
  }
}
