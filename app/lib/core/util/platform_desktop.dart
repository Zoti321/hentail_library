import 'package:flutter/foundation.dart';

/// 判断是否为桌面平台（Windows / macOS / Linux；非 Web）。
bool get isDesktop {
  if (kIsWeb) return false;
  return <TargetPlatform>[
    TargetPlatform.windows,
    TargetPlatform.macOS,
    TargetPlatform.linux,
  ].contains(defaultTargetPlatform);
}

/// OS window chrome (caption, fullscreen). Layout breakpoints stay separate.
bool get supportsDesktopWindowChrome => isDesktop;
