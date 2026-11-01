import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';

/// Initializes [windowManager] for desktop platforms (no-op on web / mobile).
///
/// Idempotent: [WindowManager.ensureInitialized] may be called more than once.
Future<void> initMd3eWindowManager() async {
  if (kIsWeb) {
    return;
  }
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return;
  }
  await windowManager.ensureInitialized();
}

void md3eWindowManagerMinimize() {
  unawaited(windowManager.minimize());
}

void md3eWindowManagerToggleMaximize() {
  unawaited(() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }());
}

/// Closes the window. Clears `preventClose` first so the close is not swallowed
/// by the guard in [Md3eWindowCloseListener].
void md3eWindowManagerClose() {
  unawaited(md3eWindowManagerCloseNow());
}

Future<void> md3eWindowManagerCloseNow() async {
  await windowManager.setPreventClose(false);
  await windowManager.close();
}
