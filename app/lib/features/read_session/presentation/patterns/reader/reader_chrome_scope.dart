import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 沉浸阅读色彩（MD3 tonal surface + 纯黑 letterbox；Lab 暂不接封面 Monet）。
abstract final class Md3eReaderImmersiveColors {
  /// 画格外 letterbox：深黑底，突出纸面与 M3E 控件对比。
  static Color letterbox(M3EColorScheme scheme) => const Color(0xFF121212);

  /// 顶/底 chrome：Surface Container 半透明（非纯黑条）。
  static Color chromeSurface(M3EColorScheme scheme) =>
      scheme.surfaceContainerHigh.withValues(alpha: 0.82);

  static Color onChrome(M3EColorScheme scheme) => scheme.onSurface;

  static Color onChromeVariant(M3EColorScheme scheme) =>
      scheme.onSurfaceVariant;

  /// 底部浮动面板顶圆角（M3 shape extra-large 量级）。
  static const double bottomChromeTopRadius = 28;
}

/// 沉浸阅读 chrome 上的前景色（继承 M3E [ColorScheme]）。
class Md3eReaderChromeScope extends InheritedWidget {
  const Md3eReaderChromeScope({
    super.key,
    required this.onChrome,
    required this.onChromeVariant,
    required super.child,
  });

  final Color onChrome;
  final Color onChromeVariant;

  static Md3eReaderChromeScope of(BuildContext context) {
    final Md3eReaderChromeScope? scope =
        context.dependOnInheritedWidgetOfExactType<Md3eReaderChromeScope>();
    assert(scope != null, 'Md3eReaderChromeScope not found');
    return scope!;
  }

  static Md3eReaderChromeScope? maybeOf(BuildContext context) {
    return context.getInheritedWidgetOfExactType<Md3eReaderChromeScope>();
  }

  @override
  bool updateShouldNotify(Md3eReaderChromeScope oldWidget) {
    return onChrome != oldWidget.onChrome ||
        onChromeVariant != oldWidget.onChromeVariant;
  }
}
