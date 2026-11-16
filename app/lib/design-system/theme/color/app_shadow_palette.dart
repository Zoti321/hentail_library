import 'package:flutter/material.dart';

/// Shadow tint values (light/dark); single source for [AppShadowTokens] assembly.
@immutable
class AppShadowPalette {
  const AppShadowPalette({
    required this.catalogCardRest,
    required this.catalogCardHover,
    required this.contextMenu,
  });

  final Color catalogCardRest;
  final Color catalogCardHover;
  final Color contextMenu;

  static const AppShadowPalette light = AppShadowPalette(
    catalogCardRest: Color(0x0F000000),
    catalogCardHover: Color(0x20000000),
    contextMenu: Color(0x29000000),
  );

  static const AppShadowPalette dark = AppShadowPalette(
    catalogCardRest: Color(0x99000000),
    catalogCardHover: Color(0xE6000000),
    contextMenu: Color(0x7A010409),
  );

  static AppShadowPalette forBrightness(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;
}
