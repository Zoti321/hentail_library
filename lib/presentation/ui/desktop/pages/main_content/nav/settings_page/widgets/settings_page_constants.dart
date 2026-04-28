import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/theme/theme.dart';

const int readerAutoPlayIntervalMin = 1;
const int readerAutoPlayIntervalMax = 60;
const double appThemeMenuWidth = 224;
const EdgeInsets settingsPagePadding = EdgeInsets.symmetric(
  horizontal: 48,
  vertical: 16,
);

TextStyle buildSettingsPageTitleStyle(ColorScheme colorScheme) {
  return TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: colorScheme.textPrimary,
  );
}
