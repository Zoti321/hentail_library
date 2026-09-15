import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/ui/core/layout/app_layout_breakpoints.dart';
import 'package:hentai_library/ui/core/layout/page_content_width_layout.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_about_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_diagnostics_rows.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_layout_constants.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_header.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/settings_page_primitives.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/locale_preference_row.dart';
import 'package:hentai_library/ui/features/settings/views/settings_page/widgets/theme_preference_row.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Settings list–detail surface (page-local category selection; no child routes).
class SettingsView extends HookWidget {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final AppThemeTokens tokens = context.tokens;
    final GlobalKey headerMeasureKey = useMemoized(GlobalKey.new);
    final ValueNotifier<double?> headerExtent = useState<double?>(null);
    final ValueNotifier<SettingsCategory> selectedCategory = useState(
      SettingsCategory.personalization,
    );
    final ValueNotifier<bool> showingNarrowDetail = useState(false);
    final ObjectRef<bool?> wasWide = useRef<bool?>(null);

    void measureHeaderExtent() {
      final RenderBox? box =
          headerMeasureKey.currentContext?.findRenderObject() as RenderBox?;
      if (box == null) {
        return;
      }
      final double height = box.size.height;
      if (headerExtent.value != height) {
        headerExtent.value = height;
      }
    }

    useEffect(() {
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => measureHeaderExtent(),
      );
      return null;
    });

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double viewportWidth = constraints.maxWidth;
        final bool isWide = !AppLayoutBreakpoints.isCompact(viewportWidth);
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

        // Crossing wide → narrow keeps the selected category on its detail pane.
        final bool? previousWide = wasWide.value;
        if (previousWide == true && !isWide) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (showingNarrowDetail.value) {
              return;
            }
            showingNarrowDetail.value = true;
          });
        }
        wasWide.value = isWide;

        void onBack() {
          if (!isWide && showingNarrowDetail.value) {
            showingNarrowDetail.value = false;
            return;
          }
          SettingsPageHeaderToolbar.popOrGoHome(context);
        }

        void selectCategory(SettingsCategory category) {
          selectedCategory.value = category;
          if (!isWide) {
            showingNarrowDetail.value = true;
          }
        }

        final AppLocalizations l10n = context.l10n;
        final bool narrowShowingDetail = !isWide && showingNarrowDetail.value;
        final String? headerTitle = narrowShowingDetail
            ? _categoryLabel(l10n, selectedCategory.value)
            : null;

        final Widget headerSection = SettingsPageHeaderSection(
          layoutTier: layoutTier,
          horizontalPadding: horizontalPadding,
          contentMaxWidth: innerMaxWidth,
          onBack: onBack,
          title: headerTitle,
        );
        final Widget header = KeyedSubtree(
          key: headerMeasureKey,
          child: headerSection,
        );

        final Widget masterList = _SettingsMasterList(
          layoutTier: layoutTier,
          selected: selectedCategory.value,
          showChevron: !isWide,
          onSelect: selectCategory,
        );
        final Widget detailPane = _SettingsDetailPane(
          category: selectedCategory.value,
          layoutTier: layoutTier,
          viewportWidth: viewportWidth,
          showTitle: isWide,
        );

        final Widget body = Padding(
          padding: EdgeInsets.only(
            top: tokens.layout.contentVerticalPadding,
            bottom:
                tokens.layout.contentAreaPadding.bottom +
                MediaQuery.viewPaddingOf(context).bottom,
          ),
          child: isWide
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    SizedBox(
                      width: kSettingsMasterPaneWidth,
                      child: masterList,
                    ),
                    SizedBox(width: tokens.spacing.lg),
                    Expanded(child: detailPane),
                  ],
                )
              : _SettingsNarrowPaneSwitcher(
                  showingDetail: showingNarrowDetail.value,
                  masterList: masterList,
                  detailPane: detailPane,
                ),
        );

        return CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: <Widget>[
            if (headerExtent.value == null)
              SliverToBoxAdapter(child: header)
            else
              SliverPersistentHeader(
                pinned: true,
                delegate: SettingsPinnedHeaderDelegate(
                  extent: headerExtent.value!,
                  child: header,
                ),
              ),
            SliverToBoxAdapter(
              child: PageContentWidthAlign(
                horizontalPadding: horizontalPadding,
                maxWidth: innerMaxWidth,
                child: body,
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Narrow master ↔ detail: slide + fade (detail from right, list from left).
class _SettingsNarrowPaneSwitcher extends StatelessWidget {
  const _SettingsNarrowPaneSwitcher({
    required this.showingDetail,
    required this.masterList,
    required this.detailPane,
  });

  final bool showingDetail;
  final Widget masterList;
  final Widget detailPane;

  @override
  Widget build(BuildContext context) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return showingDetail ? detailPane : masterList;
    }

    return ClipRect(
      child: AnimatedSwitcher(
        duration: kSettingsNarrowPaneTransitionDuration,
        reverseDuration: kSettingsNarrowPaneTransitionDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (Widget? currentChild, List<Widget> previousChildren) {
          return Stack(
            alignment: Alignment.topLeft,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (Widget child, Animation<double> animation) {
          final bool isIncoming = child.key == ValueKey<bool>(showingDetail);
          final Offset begin;
          if (isIncoming) {
            begin = showingDetail
                ? const Offset(0.12, 0)
                : const Offset(-0.08, 0);
          } else {
            begin = showingDetail
                ? const Offset(-0.08, 0)
                : const Offset(0.12, 0);
          }
          return SlideTransition(
            position: Tween<Offset>(begin: begin, end: Offset.zero).animate(
              animation,
            ),
            child: FadeTransition(opacity: animation, child: child),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<bool>(showingDetail),
          child: showingDetail ? detailPane : masterList,
        ),
      ),
    );
  }
}

class _SettingsMasterList extends StatelessWidget {
  const _SettingsMasterList({
    required this.layoutTier,
    required this.selected,
    required this.showChevron,
    required this.onSelect,
  });

  final SettingsLayoutTier layoutTier;
  final SettingsCategory selected;
  final bool showChevron;
  final ValueChanged<SettingsCategory> onSelect;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    return SettingsGroup(
      children: <Widget>[
        for (final SettingsCategory category in SettingsCategory.values)
          _SettingsMasterCategoryRow(
            layoutTier: layoutTier,
            label: _categoryLabel(l10n, category),
            icon: _categoryIcon(category),
            selected: selected == category,
            showChevron: showChevron,
            onTap: () => onSelect(category),
          ),
      ],
    );
  }
}

class _SettingsMasterCategoryRow extends StatelessWidget {
  const _SettingsMasterCategoryRow({
    required this.layoutTier,
    required this.label,
    required this.icon,
    required this.selected,
    required this.showChevron,
    required this.onTap,
  });

  final SettingsLayoutTier layoutTier;
  final String label;
  final IconData icon;
  final bool selected;
  final bool showChevron;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme cs = theme.colorScheme;
    return SettingsRow(
      layoutTier: layoutTier,
      icon: Icon(
        icon,
        size: 20,
        color: selected ? cs.primary : cs.hentai.iconDefault,
      ),
      label: label,
      onRowTap: onTap,
      action: showChevron
          ? Icon(
              LucideIcons.chevronRight,
              size: 16,
              color: cs.hentai.iconDefault,
            )
          : null,
    );
  }
}

class _SettingsDetailPane extends StatelessWidget {
  const _SettingsDetailPane({
    required this.category,
    required this.layoutTier,
    required this.viewportWidth,
    required this.showTitle,
  });

  final SettingsCategory category;
  final SettingsLayoutTier layoutTier;
  final double viewportWidth;

  /// Wide layout keeps the category title in the pane; narrow moves it to header.
  final bool showTitle;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final AppThemeTokens tokens = context.tokens;
    final Widget group = SettingsGroup(
      children: _detailRows(
        category: category,
        layoutTier: layoutTier,
        viewportWidth: viewportWidth,
      ),
    );
    if (!showTitle) {
      return group;
    }
    final String title = _categoryLabel(l10n, category);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: tokens.spacing.lg,
      children: <Widget>[
        Text(
          title,
          style: TextStyle(
            fontSize: settingsPageTitleFontSize(layoutTier),
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            color: cs.hentai.textPrimary,
          ),
        ),
        group,
      ],
    );
  }
}

List<Widget> _detailRows({
  required SettingsCategory category,
  required SettingsLayoutTier layoutTier,
  required double viewportWidth,
}) {
  return switch (category) {
    SettingsCategory.personalization => <Widget>[
      ThemePreferenceRow(layoutTier: layoutTier, viewportWidth: viewportWidth),
      LocalePreferenceRow(layoutTier: layoutTier, viewportWidth: viewportWidth),
    ],
    SettingsCategory.diagnostics => <Widget>[
      DiagnosticModeRow(layoutTier: layoutTier),
      ExportLogsRow(layoutTier: layoutTier),
    ],
    SettingsCategory.about => <Widget>[
      AutoUpdateRow(layoutTier: layoutTier),
      AboutVersionRow(layoutTier: layoutTier),
    ],
  };
}

String _categoryLabel(AppLocalizations l10n, SettingsCategory category) {
  return switch (category) {
    SettingsCategory.personalization => l10n.settingsGroupPersonalization,
    SettingsCategory.diagnostics => l10n.settingsGroupDiagnostics,
    SettingsCategory.about => l10n.settingsGroupAbout,
  };
}

IconData _categoryIcon(SettingsCategory category) {
  return switch (category) {
    SettingsCategory.personalization => LucideIcons.palette,
    SettingsCategory.diagnostics => LucideIcons.bug,
    SettingsCategory.about => LucideIcons.info,
  };
}
