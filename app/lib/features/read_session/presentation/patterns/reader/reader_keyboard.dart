import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 阅读页键盘意图（Lab；对齐生产 [readerKeyboardCommandFor] 子集）。
final class ReaderPrevPageIntent extends Intent {
  const ReaderPrevPageIntent();
}

final class ReaderNextPageIntent extends Intent {
  const ReaderNextPageIntent();
}

final class ReaderToggleAutoPlayIntent extends Intent {
  const ReaderToggleAutoPlayIntent();
}

final class ReaderToggleChromeIntent extends Intent {
  const ReaderToggleChromeIntent();
}

abstract final class ReaderKeyboard {
  static const Map<ShortcutActivator, Intent>
  shortcuts = <ShortcutActivator, Intent>{
    SingleActivator(LogicalKeyboardKey.arrowLeft): ReaderPrevPageIntent(),
    SingleActivator(LogicalKeyboardKey.arrowRight): ReaderNextPageIntent(),
    SingleActivator(LogicalKeyboardKey.space): ReaderToggleAutoPlayIntent(),
    SingleActivator(LogicalKeyboardKey.escape): ReaderToggleChromeIntent(),
  };
}
