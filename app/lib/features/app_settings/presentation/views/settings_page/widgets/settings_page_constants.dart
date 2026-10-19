import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/shared/ui/widgets/settings/settings_layout_constants.dart';

TextStyle buildSettingsPageTitleStyle(
  HentaiColorScheme semantic,
  SettingsLayoutTier layoutTier,
) {
  return TextStyle(
    fontSize: settingsPageTitleFontSize(layoutTier),
    fontWeight: FontWeight.w600,
    letterSpacing: -0.4,
    color: semantic.textPrimary,
  );
}
