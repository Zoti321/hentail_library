import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';

const double appThemeMenuWidth = 224;

TextStyle buildSettingsPageTitleStyle(ColorScheme colorScheme) {
  return TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: colorScheme.hentai.textPrimary,
  );
}
