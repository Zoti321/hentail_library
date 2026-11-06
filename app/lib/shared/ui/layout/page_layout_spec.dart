import 'package:flutter/material.dart';
import 'package:hentai_library/core/util/platform_desktop.dart';
import 'package:hentai_library/shared/ui/layout/breakpoints.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 输入形态：鼠标（指针）精度高，同一窗口档位下可比触控更紧凑。
enum LayoutInputMode { pointer, touch }

/// expanded 及以上的正文最大宽度（超宽窗口下居中，避免行过长）。
const double kPageContentMaxWidth = 1280;

/// 解析页面布局所需的全部输入（纯数据，便于测试）。
final class LayoutContext {
  const LayoutContext({
    required this.viewportWidth,
    required this.inputMode,
  });

  /// 按当前运行平台推断输入形态；[desktop] 为空时使用 [isDesktop]。
  factory LayoutContext.fromPlatform({
    required double viewportWidth,
    bool? desktop,
  }) {
    final bool pointer = desktop ?? isDesktop;
    return LayoutContext(
      viewportWidth: viewportWidth,
      inputMode: pointer ? LayoutInputMode.pointer : LayoutInputMode.touch,
    );
  }

  final double viewportWidth;
  final LayoutInputMode inputMode;

  WindowSizeClass get sizeClass =>
      WindowSizeClass.fromWidth(viewportWidth);
}

/// 页面布局规格：窗口档位 × 输入形态 → 页面所需的全部尺寸与标题样式。
///
/// 这是页面间距与标题 typography 的唯一真值。页面只读取本类的字段，
/// 不再写死数字，也不再各自拼装 metrics。
///
/// 解析是纯函数（见 [PageLayoutSpec.resolve]），测试不需要 BuildContext。
final class PageLayoutSpec {
  const PageLayoutSpec._({
    required this.sizeClass,
    required this.inputMode,
    required this.horizontalInset,
    required this.headerVerticalInset,
    required this.headerToBodyGap,
    required this.bodyBottomInset,
    required this.listItemGap,
    required this.stateTopInset,
    required this.titleFontSize,
    required this.titleFontWeight,
  });

  /// 从 [BuildContext] 解析。
  ///
  /// 优先取最近的 [PageViewport]（即页面真实视口宽度，已扣除 shell 侧栏）；
  /// 不在页面视口内（如根 Navigator 上的对话框、Widgetbook 独立页）时回退到整窗宽度。
  factory PageLayoutSpec.of(BuildContext context) {
    final PageLayoutScope? scope = context
        .dependOnInheritedWidgetOfExactType<PageLayoutScope>();
    if (scope != null) {
      return scope.layout;
    }
    return PageLayoutSpec.resolve(
      LayoutContext.fromPlatform(
        viewportWidth: MediaQuery.sizeOf(context).width,
      ),
    );
  }

  /// 纯函数解析。所有数值只在本文件的表格函数中出现。
  factory PageLayoutSpec.resolve(LayoutContext layout) {
    final WindowSizeClass sizeClass = layout.sizeClass;
    final LayoutInputMode mode = layout.inputMode;
    final double margin = _horizontalMargin(sizeClass, mode);
    final double maxWidth = sizeClass.isAtLeastExpanded
        ? kPageContentMaxWidth
        : double.infinity;
    final double paddedWidth = layout.viewportWidth - margin * 2;
    final double centeredInset = paddedWidth > maxWidth
        ? (paddedWidth - maxWidth) / 2
        : 0;
    return PageLayoutSpec._(
      sizeClass: sizeClass,
      inputMode: mode,
      horizontalInset: margin + centeredInset,
      headerVerticalInset: _headerVerticalInset(mode),
      headerToBodyGap: _headerToBodyGap(sizeClass, mode),
      bodyBottomInset: _bodyBottomInset(sizeClass, mode),
      listItemGap: _listItemGap(sizeClass, mode),
      stateTopInset: _stateTopInset(mode),
      titleFontSize: _titleFontSize(sizeClass),
      titleFontWeight: sizeClass.isCompact ? FontWeight.w700 : FontWeight.w600,
    );
  }

  final WindowSizeClass sizeClass;
  final LayoutInputMode inputMode;

  /// 页面左右实际留白（已包含超宽窗口下的居中偏移）。用于正文、页头、搜索框等。
  final double horizontalInset;

  /// 粘滞页头上下各自的内边距。
  final double headerVerticalInset;

  /// 页头（工具行）底边到正文第一块内容的间距。
  final double headerToBodyGap;

  /// 正文滚动区底部留白（分页条等与视口底边之间）。
  final double bodyBottomInset;

  /// 同一列表内相邻条目之间的间距（触控需要更大的触达间隔；鼠标列表可更紧凑）。
  final double listItemGap;

  /// 空状态 / 加载占位距离正文顶部的留白（与页头拉开距离，避免贴在工具行下）。
  final double stateTopInset;

  final double titleFontSize;
  final FontWeight titleFontWeight;

  /// 工具行固定高度（不随平台变化，保证图标按钮命中区一致）。
  static const double toolbarRowHeight = 48;

  static const double titleLetterSpacing = -0.4;
  static const double titleHeight = 1.25;

  /// 粘滞页头总高度 = 上下内边距 + 工具行。
  double get pinnedHeaderExtent => headerVerticalInset * 2 + toolbarRowHeight;

  @override
  bool operator ==(Object other) {
    return other is PageLayoutSpec &&
        other.sizeClass == sizeClass &&
        other.inputMode == inputMode &&
        other.horizontalInset == horizontalInset &&
        other.headerVerticalInset == headerVerticalInset &&
        other.headerToBodyGap == headerToBodyGap &&
        other.bodyBottomInset == bodyBottomInset &&
        other.listItemGap == listItemGap &&
        other.stateTopInset == stateTopInset &&
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
    listItemGap,
    stateTopInset,
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
    WindowSizeClass sizeClass,
    LayoutInputMode mode,
  ) {
    return switch ((mode, sizeClass)) {
      (LayoutInputMode.touch, WindowSizeClass.compact) => 16,
      (LayoutInputMode.touch, WindowSizeClass.medium) => 24,
      (LayoutInputMode.touch, WindowSizeClass.expanded) => 32,
      (LayoutInputMode.touch, WindowSizeClass.large) => 40,
      (LayoutInputMode.touch, WindowSizeClass.extraLarge) => 40,
      (LayoutInputMode.pointer, WindowSizeClass.compact) => 16,
      (LayoutInputMode.pointer, WindowSizeClass.medium) => 20,
      (LayoutInputMode.pointer, WindowSizeClass.expanded) => 24,
      (LayoutInputMode.pointer, WindowSizeClass.large) => 32,
      (LayoutInputMode.pointer, WindowSizeClass.extraLarge) => 32,
    };
  }

  static double _headerVerticalInset(LayoutInputMode mode) {
    return switch (mode) {
      LayoutInputMode.touch => 12,
      LayoutInputMode.pointer => 8,
    };
  }

  static double _headerToBodyGap(
    WindowSizeClass sizeClass,
    LayoutInputMode mode,
  ) {
    return switch ((mode, sizeClass)) {
      (LayoutInputMode.touch, WindowSizeClass.compact) => 16,
      (LayoutInputMode.touch, WindowSizeClass.medium) => 20,
      (LayoutInputMode.touch, _) => 24,
      (LayoutInputMode.pointer, WindowSizeClass.compact) => 12,
      (LayoutInputMode.pointer, _) => 16,
    };
  }

  static double _bodyBottomInset(
    WindowSizeClass sizeClass,
    LayoutInputMode mode,
  ) {
    return switch ((mode, sizeClass)) {
      (LayoutInputMode.touch, WindowSizeClass.compact) => 24,
      (LayoutInputMode.touch, WindowSizeClass.medium) => 24,
      (LayoutInputMode.touch, _) => 32,
      (LayoutInputMode.pointer, WindowSizeClass.compact) => 16,
      (LayoutInputMode.pointer, _) => 24,
    };
  }

  static double _listItemGap(
    WindowSizeClass sizeClass,
    LayoutInputMode mode,
  ) {
    return switch ((mode, sizeClass)) {
      (LayoutInputMode.touch, WindowSizeClass.compact) => 12,
      (LayoutInputMode.touch, _) => 16,
      (LayoutInputMode.pointer, _) => 8,
    };
  }

  static double _stateTopInset(LayoutInputMode mode) {
    return switch (mode) {
      LayoutInputMode.touch => 48,
      LayoutInputMode.pointer => 32,
    };
  }

  static double _titleFontSize(WindowSizeClass sizeClass) {
    return switch (sizeClass) {
      WindowSizeClass.compact => 24,
      WindowSizeClass.medium => 24,
      WindowSizeClass.expanded => 28,
      WindowSizeClass.large => 32,
      WindowSizeClass.extraLarge => 32,
    };
  }
}

/// 页面视口：用 [LayoutBuilder] 量出 [child] 实际可用宽度（shell 内容区，已扣除侧栏），
/// 并把解析好的 [PageLayoutSpec] 通过 [PageLayoutScope] 下发给子树。
///
/// 只需在 shell 内容区包一次；其下所有 [PageLayoutSpec.of] 自动取视口宽度。
class PageViewport extends StatelessWidget {
  const PageViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return PageLayoutScope(
          layout: PageLayoutSpec.resolve(
            LayoutContext.fromPlatform(viewportWidth: constraints.maxWidth),
          ),
          child: child,
        );
      },
    );
  }
}

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
