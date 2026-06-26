import 'package:flutter/material.dart';

ThemeData buildMobileMaterialTheme(Brightness brightness) {
  return ThemeData(
    useMaterial3: true,
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
      brightness: brightness,
    ),
  );
}
