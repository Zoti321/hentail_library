import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:hentai_library/shared/ui/l10n/library_display_target_l10n.dart';

/// 漫画 / 系列切换：[`M3ETabs`] primary + 局部 [`M3ETabTheme`]（动画指示条、state layer）。
///
/// 形状与动效：通过 [LibraryPageHeaderMetrics.displayTargetTabThemeFor] 注入
/// （divider、indicator 尺寸/圆角/inset、spring、state opacity）。SDK 不提供圆角
/// state layer 槽形；需要胶囊形态可参考 M3E Segmented Button。
class LibraryDisplayTargetTabs extends StatelessWidget {
  const LibraryDisplayTargetTabs({
    super.key,
    required this.displayTarget,
    required this.sizeClass,
    required this.onChanged,
    this.centered = true,
  });

  final LibraryDisplayTarget displayTarget;
  final WindowSizeClass sizeClass;
  final ValueChanged<LibraryDisplayTarget> onChanged;

  /// When false, tabs align to the start (catalog toolbar / Kazumi-style row).
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final int selectedIndex = displayTarget == LibraryDisplayTarget.comics
        ? 0
        : 1;
    final List<String> tabLabels = <String>[
      l10n.libraryDisplayTargetTabLabel(LibraryDisplayTarget.comics),
      l10n.libraryDisplayTargetTabLabel(LibraryDisplayTarget.series),
    ];
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETabTheme tabTheme =
        LibraryPageHeaderMetrics.displayTargetTabThemeFor(sizeClass);

    final TextStyle selectedLabelStyle = tabTheme.labelStyle(
      theme.typeScale,
      scheme,
      selected: true,
      variant: M3ETabsVariant.primary,
    );
    final double barWidth = LibraryPageHeaderMetrics.displayTargetTabsBarWidth(
      tabLabels: tabLabels,
      labelStyle: selectedLabelStyle,
      textDirection: Directionality.of(context),
    );

    // M3ETabs bar fill is [M3ETabTheme.backgroundColor] → `scheme.surface` (M3 spec).
    // Lab browse canvas is [labBrowseCanvasColor]; alias surface locally so the
    // bar matches the page without repainting the whole scroll view.
    final M3EColorScheme tabsColorScheme = scheme.copyWith(
      surface: labBrowseCanvasColor(scheme),
    );

    final Widget tabs = SizedBox(
      width: barWidth,
      child: M3ETheme(
        data: theme.copyWith(colorScheme: tabsColorScheme, tabTheme: tabTheme),
        child: M3ETabs(
          variant: M3ETabsVariant.primary,
          scrollable: true,
          tabs: <M3ETab>[
            for (final String label in tabLabels) M3ETab(label: label),
          ],
          selectedIndex: selectedIndex,
          onTabSelected: (int index) {
            onChanged(
              index == 0
                  ? LibraryDisplayTarget.comics
                  : LibraryDisplayTarget.series,
            );
          },
        ),
      ),
    );

    if (centered) {
      return Center(child: tabs);
    }
    return Align(alignment: Alignment.centerLeft, child: tabs);
  }
}
