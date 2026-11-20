import 'package:flutter/material.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_detail_panes.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_sections.dart';

/// Lab / Widgetbook section composition: production tiles where faked providers
/// suffice; reading / metadataBackup keep in-memory mocks.
List<Widget> labSettingsSectionsFor(
  BuildContext context,
  SettingsCategory category, {
  required SettingsLabState labState,
  required ValueChanged<SettingsLabState> onLabStateChanged,
  SettingsOptionLabels optionLabels = const SettingsOptionLabels(),
  bool showUnwiredTiles = true,
}) {
  return switch (category) {
    SettingsCategory.reading || SettingsCategory.metadataBackup =>
      labMockSectionsForCategory(
        context,
        category,
        labState: labState,
        onLabStateChanged: onLabStateChanged,
        optionLabels: optionLabels,
        showUnwiredTiles: showUnwiredTiles,
      ),
    _ => settingsSectionsFor(category, context),
  };
}
