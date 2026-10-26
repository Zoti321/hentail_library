import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:window_manager/window_manager.dart';

bool _md3eWindowManagerInitialized = false;

/// Whether [window_manager] was initialized via [initMd3eWindowManager].
bool get isMd3eWindowManagerInitialized => _md3eWindowManagerInitialized;

/// Initializes desktop window controls (no-op on web / mobile).
Future<void> initMd3eWindowManager() async {
  if (kIsWeb) {
    return;
  }
  if (!Platform.isWindows && !Platform.isLinux && !Platform.isMacOS) {
    return;
  }
  await windowManager.ensureInitialized();
  _md3eWindowManagerInitialized = true;
}

void md3eWindowManagerMinimize() {
  if (!_md3eWindowManagerInitialized) {
    return;
  }
  unawaited(windowManager.minimize());
}

void md3eWindowManagerToggleMaximize() {
  if (!_md3eWindowManagerInitialized) {
    return;
  }
  unawaited(() async {
    if (await windowManager.isMaximized()) {
      await windowManager.unmaximize();
    } else {
      await windowManager.maximize();
    }
  }());
}

void md3eWindowManagerClose() {
  if (!_md3eWindowManagerInitialized) {
    return;
  }
  unawaited(windowManager.close());
}
