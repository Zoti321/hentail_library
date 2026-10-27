import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_display_target.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_page_header_metrics.dart';
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

  final Md3eLibraryDisplayTarget displayTarget;
  final Md3eWindowSizeClass sizeClass;
  final ValueChanged<Md3eLibraryDisplayTarget> onChanged;

  /// When false, tabs align to the start (catalog toolbar / Kazumi-style row).
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = displayTarget == Md3eLibraryDisplayTarget.comics
        ? 0
        : 1;
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
          tabs: const <M3ETab>[
            M3ETab(label: '漫画'),
            M3ETab(label: '系列'),
          ],
          selectedIndex: selectedIndex,
          onTabSelected: (int index) {
            onChanged(
              index == 0
                  ? Md3eLibraryDisplayTarget.comics
                  : Md3eLibraryDisplayTarget.series,
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
