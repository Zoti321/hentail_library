import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_md3e_sections.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_page_body.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/shared/domain/models/app_setting.dart';

/// 设置页（MD3E Cutover）：生产 `/settings` 路由入口。
class SettingsMd3ePage extends ConsumerWidget {
  const SettingsMd3ePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AsyncValue<AppSetting> settingsAsync = ref.watch(settingsProvider);
    final AppSetting? setting = settingsAsync.asData?.value;
    if (setting == null) {
      if (settingsAsync.hasError) {
        return Center(
          child: Text(
            settingsAsync.error.toString(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        );
      }
      return const Center(child: CircularProgressIndicator());
    }

    return Md3eSettingsPage(
        key: const Key('settings_md3e'),
        sectionsBuilder: (BuildContext context, Md3eSettingsCategory category) {
          return settingsMd3eSectionsFor(category);
        },
      );
  }
}
