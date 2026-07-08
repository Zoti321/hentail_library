import 'package:flutter/material.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_about_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_library_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_header.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
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
          onOpenNavigation: layoutTier == SettingsLayoutTier.compact
              ? openAppShellNavigationDrawer
              : null,
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
            SliverPadding(
              padding: EdgeInsets.fromLTRB(
                horizontalPadding,
                tokens.layout.contentVerticalPadding,
                horizontalPadding,
                tokens.layout.contentAreaPadding.bottom,
              ),
              sliver: SliverToBoxAdapter(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: innerMaxWidth),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 24,
                      children: <Widget>[
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
              ),
            ),
          ],
        );
      },
    );
  }
}
