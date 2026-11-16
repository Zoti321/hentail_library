/// 设置 MD3E 页（生产路由入口，ADR-0034 public/ui）。
///
/// 组合根通过 [SettingsPage.sectionsBuilder] 注入「阅读」「元数据备份」等
/// owner 分区（ADR-0046 §6）；未注入的分类渲染为空列表。
library;

export 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_catalog.dart'
    show SettingsCategory, SettingsCategoryInfo, settingsCategoryInfo;
export 'package:hentai_library/features/app_settings/presentation/patterns/settings/settings_detail_panes.dart'
    show SettingsSectionsBuilder;
export 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_page.dart';
export 'package:hentai_library/features/app_settings/presentation/views/settings_page/settings_sections.dart'
    show settingsSectionsFor;
