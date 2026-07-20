import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_about_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_diagnostics_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_library_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_header.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/locale_preference_row.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/theme_preference_row.dart';
import 'package:hentai_library/ui/features/shell/views/responsive_app_shell.dart';

class SettingsView extends StatefulWidget {
  const SettingsView({super.key});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  final GlobalKey _headerMeasureKey = GlobalKey();
  double? _headerExtent;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback(_measureHeaderExtent);
  }

  void _measureHeaderExtent(Duration _) {
    final RenderBox? box =
        _headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
    if (!mounted || box == null) {
      return;
    }
    final double height = box.size.height;
    if (_headerExtent != height) {
      setState(() => _headerExtent = height);
    }
  }

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final l10n = context.l10n;
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

        final Widget headerSection = SettingsPageHeaderSection(
          layoutTier: layoutTier,
          horizontalPadding: horizontalPadding,
          contentMaxWidth: innerMaxWidth,
          onOpenNavigation: appShellPageNavigationOpener(context),
        );
        final Widget header = KeyedSubtree(
          key: _headerMeasureKey,
          child: headerSection,
        );

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (_headerExtent == null)
              SliverToBoxAdapter(child: header)
            else
              SliverPersistentHeader(
                pinned: true,
                delegate: SettingsPinnedHeaderDelegate(
                  extent: _headerExtent!,
                  child: header,
                ),
              ),
            SliverToBoxAdapter(
              child: PageContentWidthAlign(
                horizontalPadding: horizontalPadding,
                maxWidth: innerMaxWidth,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: tokens.layout.contentVerticalPadding,
                    bottom: tokens.layout.contentAreaPadding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    spacing: 24,
                    children: <Widget>[
                      SettingsGroup(
                        title: l10n.settingsGroupPersonalization,
                        children: <Widget>[
                          ThemePreferenceRow(
                            layoutTier: layoutTier,
                            viewportWidth: viewportWidth,
                          ),
                          LocalePreferenceRow(
                            layoutTier: layoutTier,
                            viewportWidth: viewportWidth,
                          ),
                        ],
                      ),
                      SettingsGroup(
                        title: l10n.settingsGroupLibrary,
                        children: <Widget>[
                          LibraryLocationRow(layoutTier: layoutTier),
                          AutoScanRow(layoutTier: layoutTier),
                        ],
                      ),
                      SettingsGroup(
                        title: l10n.settingsGroupDiagnostics,
                        children: <Widget>[
                          DiagnosticModeRow(layoutTier: layoutTier),
                          ExportLogsRow(layoutTier: layoutTier),
                        ],
                      ),
                      SettingsGroup(
                        title: l10n.settingsGroupAbout,
                        children: <Widget>[
                          AutoUpdateRow(layoutTier: layoutTier),
                          AboutVersionRow(layoutTier: layoutTier),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
