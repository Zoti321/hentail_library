import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_about_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_library_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/theme_preference_row.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final AppThemeTokens tokens = context.tokens;
    return SingleChildScrollView(
      padding: tokens.layout.contentAreaPadding,
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
            children: <Widget>[LibraryLocationRow(), AutoScanRow()],
          ),
          const SettingsGroup(
            title: '关于',
            children: <Widget>[AutoUpdateRow(), AboutVersionRow()],
          ),
        ],
      ),
    );
  }
}
