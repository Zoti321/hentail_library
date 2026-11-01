import 'package:flutter/material.dart';
import 'package:hentai_library/core/util/platform_desktop.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 输入形态：鼠标（指针）精度高，同一窗口档位下可比触控更紧凑。
enum LayoutInputMode { pointer, touch }

/// expanded 及以上的正文最大宽度（超宽窗口下居中，避免行过长）。
const double kMd3ePageContentMaxWidth = 1280;

/// 解析页面布局所需的全部输入（纯数据，便于测试）。
final class Md3eLayoutContext {
  const Md3eLayoutContext({
    required this.viewportWidth,
    required this.inputMode,
  });

  /// 按当前运行平台推断输入形态；[desktop] 为空时使用 [isDesktop]。
  factory Md3eLayoutContext.fromPlatform({
    required double viewportWidth,
    bool? desktop,
  }) {
    final bool pointer = desktop ?? isDesktop;
    return Md3eLayoutContext(
      viewportWidth: viewportWidth,
      inputMode: pointer ? LayoutInputMode.pointer : LayoutInputMode.touch,
    );
  }

  final double viewportWidth;
  final LayoutInputMode inputMode;

  Md3eWindowSizeClass get sizeClass =>
      Md3eWindowSizeClass.fromWidth(viewportWidth);
}

/// 页面布局规格：窗口档位 × 输入形态 → 页面所需的全部尺寸与标题样式。
///
/// 这是页面间距与标题 typography 的唯一真值。页面只读取本类的字段，
/// 不再写死数字，也不再各自拼装 metrics。
///
/// 解析是纯函数（见 [Md3ePageLayoutSpec.resolve]），测试不需要 BuildContext。
final class Md3ePageLayoutSpec {
  const Md3ePageLayoutSpec._({
    required this.sizeClass,
    required this.inputMode,
    required this.horizontalInset,
    required this.headerVerticalInset,
    required this.headerToBodyGap,
    required this.bodyBottomInset,
    required this.titleFontSize,
    required this.titleFontWeight,
  });

  /// 从 [BuildContext] 解析：窗口宽度取 [MediaQuery]，输入形态取当前平台。
  factory Md3ePageLayoutSpec.of(BuildContext context) {
    return Md3ePageLayoutSpec.resolve(
      Md3eLayoutContext.fromPlatform(
        viewportWidth: MediaQuery.sizeOf(context).width,
      ),
    );
  }

  /// 纯函数解析。所有数值只在本文件的表格函数中出现。
  factory Md3ePageLayoutSpec.resolve(Md3eLayoutContext layout) {
    final Md3eWindowSizeClass sizeClass = layout.sizeClass;
    final LayoutInputMode mode = layout.inputMode;
    final double margin = _horizontalMargin(sizeClass, mode);
    final double maxWidth = sizeClass.isAtLeastExpanded
        ? kMd3ePageContentMaxWidth
        : double.infinity;
    final double paddedWidth = layout.viewportWidth - margin * 2;
    final double centeredInset = paddedWidth > maxWidth
        ? (paddedWidth - maxWidth) / 2
        : 0;
    return Md3ePageLayoutSpec._(
      sizeClass: sizeClass,
      inputMode: mode,
      horizontalInset: margin + centeredInset,
      headerVerticalInset: _headerVerticalInset(mode),
      headerToBodyGap: _headerToBodyGap(sizeClass, mode),
      bodyBottomInset: _bodyBottomInset(sizeClass, mode),
      titleFontSize: _titleFontSize(sizeClass),
      titleFontWeight: sizeClass.isCompact ? FontWeight.w700 : FontWeight.w600,
    );
  }

  final Md3eWindowSizeClass sizeClass;
  final LayoutInputMode inputMode;

  /// 页面左右实际留白（已包含超宽窗口下的居中偏移）。用于正文、页头、搜索框等。
  final double horizontalInset;

  /// 粘滞页头上下各自的内边距。
  final double headerVerticalInset;

  /// 页头（工具行）底边到正文第一块内容的间距。
  final double headerToBodyGap;

  /// 正文滚动区底部留白（分页条等与视口底边之间）。
  final double bodyBottomInset;

  final double titleFontSize;
  final FontWeight titleFontWeight;

  /// 工具行固定高度（不随平台变化，保证图标按钮命中区一致）。
  static const double toolbarRowHeight = 48;

  static const double titleLetterSpacing = -0.4;
  static const double titleHeight = 1.25;

  /// 粘滞页头总高度 = 上下内边距 + 工具行。
  double get pinnedHeaderExtent =>
      headerVerticalInset * 2 + toolbarRowHeight;

  @override
  bool operator ==(Object other) {
    return other is Md3ePageLayoutSpec &&
        other.sizeClass == sizeClass &&
        other.inputMode == inputMode &&
        other.horizontalInset == horizontalInset &&
        other.headerVerticalInset == headerVerticalInset &&
        other.headerToBodyGap == headerToBodyGap &&
        other.bodyBottomInset == bodyBottomInset &&
        other.titleFontSize == titleFontSize &&
        other.titleFontWeight == titleFontWeight;
  }

  @override
  int get hashCode => Object.hash(
    sizeClass,
    inputMode,
    horizontalInset,
    headerVerticalInset,
    headerToBodyGap,
    bodyBottomInset,
    titleFontSize,
    titleFontWeight,
  );

  /// 页面标题统一样式：基于 `headlineSmall`，字号/字重由窗口档位决定。
  TextStyle titleStyle(M3ETypeScale typeScale, Color color) {
    return typeScale.headlineSmall.copyWith(
      fontSize: titleFontSize,
      fontWeight: titleFontWeight,
      letterSpacing: titleLetterSpacing,
      height: titleHeight,
      color: color,
    );
  }

  static double _horizontalMargin(
    Md3eWindowSizeClass sizeClass,
    LayoutInputMode mode,
  ) {
    return switch ((mode, sizeClass)) {
      (LayoutInputMode.touch, Md3eWindowSizeClass.compact) => 16,
      (LayoutInputMode.touch, Md3eWindowSizeClass.medium) => 24,
      (LayoutInputMode.touch, Md3eWindowSizeClass.expanded) => 32,
      (LayoutInputMode.touch, Md3eWindowSizeClass.large) => 40,
      (LayoutInputMode.touch, Md3eWindowSizeClass.extraLarge) => 40,
      (LayoutInputMode.pointer, Md3eWindowSizeClass.compact) => 16,
      (LayoutInputMode.pointer, Md3eWindowSizeClass.medium) => 20,
      (LayoutInputMode.pointer, Md3eWindowSizeClass.expanded) => 24,
      (LayoutInputMode.pointer, Md3eWindowSizeClass.large) => 32,
      (LayoutInputMode.pointer, Md3eWindowSizeClass.extraLarge) => 32,
    };
  }

  static double _headerVerticalInset(LayoutInputMode mode) {
    return switch (mode) {
      LayoutInputMode.touch => 12,
      LayoutInputMode.pointer => 8,
    };
  }

  static double _headerToBodyGap(
    Md3eWindowSizeClass sizeClass,
    LayoutInputMode mode,
  ) {
    return switch ((mode, sizeClass)) {
      (LayoutInputMode.touch, Md3eWindowSizeClass.compact) => 16,
      (LayoutInputMode.touch, Md3eWindowSizeClass.medium) => 20,
      (LayoutInputMode.touch, _) => 24,
      (LayoutInputMode.pointer, Md3eWindowSizeClass.compact) => 12,
      (LayoutInputMode.pointer, _) => 16,
    };
  }

  static double _bodyBottomInset(
    Md3eWindowSizeClass sizeClass,
    LayoutInputMode mode,
  ) {
    return switch ((mode, sizeClass)) {
      (LayoutInputMode.touch, Md3eWindowSizeClass.compact) => 24,
      (LayoutInputMode.touch, Md3eWindowSizeClass.medium) => 24,
      (LayoutInputMode.touch, _) => 32,
      (LayoutInputMode.pointer, Md3eWindowSizeClass.compact) => 16,
      (LayoutInputMode.pointer, _) => 24,
    };
  }

  static double _titleFontSize(Md3eWindowSizeClass sizeClass) {
    return switch (sizeClass) {
      Md3eWindowSizeClass.compact => 24,
      Md3eWindowSizeClass.medium => 24,
      Md3eWindowSizeClass.expanded => 28,
      Md3eWindowSizeClass.large => 32,
      Md3eWindowSizeClass.extraLarge => 32,
    };
  }
}
