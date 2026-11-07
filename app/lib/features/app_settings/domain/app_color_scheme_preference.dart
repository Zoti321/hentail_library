import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

/// [AppColorSchemePreference] → theme `colorSchemeId`（与 JSON / seed 表对齐）。
String colorSchemeIdForPreference(AppColorSchemePreference preference) {
  return switch (preference) {
    AppColorSchemePreference.brand => 'brand',
    AppColorSchemePreference.teal => 'teal',
    AppColorSchemePreference.cyan => 'cyan',
    AppColorSchemePreference.blue => 'blue',
    AppColorSchemePreference.indigo => 'indigo',
    AppColorSchemePreference.deepPurple => 'deepPurple',
    AppColorSchemePreference.violet => 'violet',
    AppColorSchemePreference.pink => 'pink',
    AppColorSchemePreference.sakura => 'sakura',
    AppColorSchemePreference.yellow => 'yellow',
    AppColorSchemePreference.orange => 'orange',
    AppColorSchemePreference.deepOrange => 'deepOrange',
    AppColorSchemePreference.green => 'green',
  };
}
