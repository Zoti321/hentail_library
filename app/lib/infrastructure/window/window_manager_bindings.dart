import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_acrylic/flutter_acrylic.dart';
import 'package:window_manager/window_manager.dart';

Future<void> initializeWindowManager() => windowManager.ensureInitialized();

Future<void> windowManagerSetFullscreen(bool value) =>
    windowManager.setFullScreen(value);

/// Native configuration selected by the application composition root.
Future<void> configureDesktopWindow({
  required String title,
  required Size minimumSize,
}) async {
  await windowManager.ensureInitialized();
  await windowManager.waitUntilReadyToShow();
  await windowManager.setTitle(title);
  await windowManager.setTitleBarStyle(
    TitleBarStyle.hidden,
    windowButtonVisibility: true,
  );
  await windowManager.setMinimumSize(minimumSize);
  await windowManager.center();
  await windowManager.show();
  await windowManager.setPreventClose(true);
  await windowManager.setSkipTaskbar(false);
  await Window.initialize();
  await Window.setEffect(
    effect: WindowEffect.solid,
    color: Colors.white,
    dark: false,
  );
}

void windowManagerStartDragging() {
  unawaited(windowManager.startDragging());
}

void windowManagerMinimize() {
  unawaited(windowManager.minimize());
}

void windowManagerToggleMaximize() {
  unawaited(() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }());
}

/// Closes the window. Clears `preventClose` first so the close is not swallowed
/// by the native close guard.
void windowManagerClose() {
  unawaited(windowManagerCloseNow());
}

Future<void> windowManagerCloseNow() async {
  await windowManager.setPreventClose(false);
  await windowManager.close();
}
