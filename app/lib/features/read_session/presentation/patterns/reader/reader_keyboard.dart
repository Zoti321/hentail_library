import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 阅读页键盘意图（Lab；对齐生产 [readerKeyboardCommandFor] 子集）。
final class Md3eReaderPrevPageIntent extends Intent {
  const Md3eReaderPrevPageIntent();
}

final class Md3eReaderNextPageIntent extends Intent {
  const Md3eReaderNextPageIntent();
}

final class Md3eReaderToggleAutoPlayIntent extends Intent {
  const Md3eReaderToggleAutoPlayIntent();
}

final class Md3eReaderToggleChromeIntent extends Intent {
  const Md3eReaderToggleChromeIntent();
}

abstract final class Md3eReaderKeyboard {
  static const Map<ShortcutActivator, Intent> shortcuts =
      <ShortcutActivator, Intent>{
        SingleActivator(LogicalKeyboardKey.arrowLeft):
            Md3eReaderPrevPageIntent(),
        SingleActivator(LogicalKeyboardKey.arrowRight):
            Md3eReaderNextPageIntent(),
        SingleActivator(LogicalKeyboardKey.space):
            Md3eReaderToggleAutoPlayIntent(),
        SingleActivator(LogicalKeyboardKey.escape):
            Md3eReaderToggleChromeIntent(),
      };
}
