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

/// 配色弹窗展示顺序：按 seed 色相环（HCT hue）升序，相近色系相邻。
///
/// 暖色（朱砂→琥珀）→ 绿 → 青 → 蓝紫 → 品红；不含与 brand 同色的 [AppColorSchemePreference.violet]。
const List<AppColorSchemePreference> kColorSchemePickerOrder =
    <AppColorSchemePreference>[
      AppColorSchemePreference.deepOrange,
      AppColorSchemePreference.orange,
      AppColorSchemePreference.yellow,
      AppColorSchemePreference.green,
      AppColorSchemePreference.teal,
      AppColorSchemePreference.cyan,
      AppColorSchemePreference.blue,
      AppColorSchemePreference.indigo,
      AppColorSchemePreference.deepPurple,
      AppColorSchemePreference.brand,
      AppColorSchemePreference.pink,
      AppColorSchemePreference.sakura,
    ];

