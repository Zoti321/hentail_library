import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/widgets/actions/ghost_button.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_about_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_library_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/theme_preference_row.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class SettingsView extends StatelessWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final ThemeData theme = Theme.of(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        final SettingsLayoutTier layoutTier = settingsLayoutTierForWidth(
          viewportWidth,
        );
        final double horizontalPadding = settingsContentHorizontalPadding(
          layoutTier,
        );
        final double innerMaxWidth = settingsInnerContentMaxWidth(
          layoutTier,
          viewportWidth,
        );

        return SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
            horizontalPadding,
            tokens.layout.contentAreaPadding.top,
            horizontalPadding,
            tokens.layout.contentAreaPadding.bottom,
          ),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: innerMaxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 24,
                children: <Widget>[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        if (layoutTier ==
                            SettingsLayoutTier.compact) ...<Widget>[
                          GhostButton.icon(
                            icon: LucideIcons.menu,
                            semanticLabel: '打开导航菜单',
                            tooltip: '',
                            iconSize: 16,
                            size: 32,
                            borderRadius: 8,
                            foregroundColor:
                                theme.colorScheme.hentai.iconDefault,
                            hoverColor: theme.hoverColor,
                            overlayColor: theme.hoverColor,
                            onPressed: openAppShellNavigationDrawer,
                          ),
                          const SizedBox(height: 8),
                        ],
                        Text(
                          '设置',
                          style: buildSettingsPageTitleStyle(
                            theme.colorScheme,
                            layoutTier,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SettingsGroup(
                    title: '个性化',
                    children: <Widget>[
                      ThemePreferenceRow(
                        layoutTier: layoutTier,
                        viewportWidth: viewportWidth,
                      ),
                    ],
                  ),
                  SettingsGroup(
                    title: '漫画库',
                    children: <Widget>[
                      LibraryLocationRow(layoutTier: layoutTier),
                      AutoScanRow(layoutTier: layoutTier),
                    ],
                  ),
                  SettingsGroup(
                    title: '关于',
                    children: <Widget>[
                      AutoUpdateRow(layoutTier: layoutTier),
                      AboutVersionRow(layoutTier: layoutTier),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
