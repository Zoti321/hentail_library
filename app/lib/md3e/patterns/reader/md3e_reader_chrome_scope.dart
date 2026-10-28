import 'package:flutter/material.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 沉浸阅读 chrome 上的前景色（letterbox 上浅字/浅图标，不用灰浮岛）。
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

abstract final class Md3eReaderImmersiveColors {
  static Color letterbox(M3EColorScheme scheme) => scheme.scrim;

  static Color onChrome(M3EColorScheme scheme) =>
      scheme.surface.withValues(alpha: 0.94);

  static Color onChromeVariant(M3EColorScheme scheme) =>
      scheme.surface.withValues(alpha: 0.68);
}
