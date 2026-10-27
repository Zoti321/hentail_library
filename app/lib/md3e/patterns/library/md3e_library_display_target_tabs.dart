import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画 / 系列切换：[`M3ETabs`] primary + 局部 [`M3ETabTheme`]（动画指示条、state layer）。
///
/// 形状与动效：通过 [Md3eLibraryPageHeaderMetrics.displayTargetTabThemeFor] 注入
/// （divider、indicator 尺寸/圆角/inset、spring、state opacity）。SDK 不提供圆角
/// state layer 槽形；需要胶囊形态可参考生产 [CapsuleTabBar] 或 M3E Segmented Button。
class Md3eLibraryDisplayTargetTabs extends StatelessWidget {
  const Md3eLibraryDisplayTargetTabs({
    super.key,
    required this.displayTarget,
    required this.sizeClass,
    required this.onChanged,
    this.centered = true,
  });

  final LibraryDisplayTarget displayTarget;
  final Md3eWindowSizeClass sizeClass;
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
        Md3eLibraryPageHeaderMetrics.displayTargetTabThemeFor(sizeClass);

    final TextStyle selectedLabelStyle = tabTheme.labelStyle(
      theme.typeScale,
      scheme,
      selected: true,
      variant: M3ETabsVariant.primary,
    );
    final double barWidth =
        Md3eLibraryPageHeaderMetrics.displayTargetTabsBarWidth(
          tabLabels: tabLabels,
          labelStyle: selectedLabelStyle,
          textDirection: Directionality.of(context),
        );

    final Widget tabs = SizedBox(
      width: barWidth,
      child: M3ETheme(
        data: theme.copyWith(tabTheme: tabTheme),
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
