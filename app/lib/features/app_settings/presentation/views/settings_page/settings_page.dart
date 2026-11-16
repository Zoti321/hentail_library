import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/app_settings/presentation/view_models/settings_notifier.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_sections.dart';
import 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_page_body.dart';
import 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart';
import 'package:hentai_library/features/app_settings/domain/app_setting.dart';

/// 设置页（MD3E Cutover）：生产 `/settings` 路由入口。
///
/// 默认只渲染 `app_settings` 自有分类；「阅读」由 `reader`、「元数据备份」由
/// `metadata_backup` 提供，由组合根经 [sectionsBuilder] 组合（ADR-0046 §6）。
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key, this.sectionsBuilder});

  final SettingsSectionsBuilder? sectionsBuilder;

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

    return SettingsLayout(
      key: const Key('settings'),
      sectionsBuilder:
          sectionsBuilder ??
          (BuildContext context, SettingsCategory category) =>
              settingsSectionsFor(category, context),
    );
  }
}
