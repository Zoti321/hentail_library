import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

/// [AppColorSchemePreference] → theme `colorSchemeId`（与 JSON / seed 表对齐）。
String colorSchemeIdForPreference(AppColorSchemePreference preference) {
  return switch (preference) {
    AppColorSchemePreference.brand => 'brand',
    AppColorSchemePreference.teal => 'teal',
    AppColorSchemePreference.blue => 'blue',
    AppColorSchemePreference.indigo => 'indigo',
    AppColorSchemePreference.violet => 'violet',
    AppColorSchemePreference.pink => 'pink',
    AppColorSchemePreference.yellow => 'yellow',
    AppColorSchemePreference.orange => 'orange',
    AppColorSchemePreference.deepOrange => 'deepOrange',
  };
}
