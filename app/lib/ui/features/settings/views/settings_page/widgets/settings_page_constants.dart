import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';

TextStyle buildSettingsPageTitleStyle(
  ColorScheme colorScheme,
  SettingsLayoutTier layoutTier,
) {
  return TextStyle(
    fontSize: settingsPageTitleFontSize(layoutTier),
    fontWeight: FontWeight.w600,
    color: colorScheme.hentai.textPrimary,
  );
}
