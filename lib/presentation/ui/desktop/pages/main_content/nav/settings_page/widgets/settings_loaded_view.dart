import 'package:flutter/material.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_about_rows.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_cache_rows.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_library_rows.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_page_constants.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_reader_rows.dart';
import 'package:hentai_library/presentation/ui/desktop/pages/main_content/nav/settings_page/widgets/settings_theme_row.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return SingleChildScrollView(
      padding: settingsPagePadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 24,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '设置',
              style: buildSettingsPageTitleStyle(theme.colorScheme),
            ),
          ),
          const SettingsGroup(
            title: '个性化',
            children: <Widget>[ThemePreferenceRow()],
          ),
          const SettingsGroup(
            title: '漫画库',
            children: <Widget>[
              LibraryLocationRow(),
              AutoScanRow(),
              LibraryHideComicsInSeriesRow(),
              HealthyModeRow(),
            ],
          ),
          const SettingsGroup(
            title: '缓存',
            children: <Widget>[
              ArchiveCoverDiskCacheRow(),
              ArchiveCoverCacheUsageRow(),
            ],
          ),
          const SettingsGroup(
            title: '阅读',
            children: <Widget>[ReaderAutoPlayIntervalRow()],
          ),
          const SettingsGroup(
            title: '关于',
            children: <Widget>[AboutVersionRow()],
          ),
        ],
      ),
    );
  }
}
