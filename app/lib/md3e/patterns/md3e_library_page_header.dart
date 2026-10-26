import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/md3e_library_page_header_metrics.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Library catalog display target (comics grid vs series grid).
enum Md3eLibraryDisplayTarget {
  comics,
  series,
}

/// Default page-size choices for the overflow submenu (Lab).
const List<int> kMd3eLibraryPageSizeOptions = <int>[20, 50, 100, 200];

/// 漫画库页内头部：标题、[M3ETabs]、操作按钮（Lab pattern）。
class Md3eLibraryPageHeader extends StatelessWidget {
  const Md3eLibraryPageHeader({
    super.key,
    this.title = '漫画库',
    required this.displayTarget,
    this.onDisplayTargetChanged,
    this.onFilterSort,
    this.overflowMenuEntries = const <M3EMenuNode>[],
    this.pageSize,
    this.onPageSizeChanged,
    this.pageSizeOptions = kMd3eLibraryPageSizeOptions,
    this.filterSortActive = false,
  });

  final String title;
  final Md3eLibraryDisplayTarget displayTarget;
  final ValueChanged<Md3eLibraryDisplayTarget>? onDisplayTargetChanged;
  final VoidCallback? onFilterSort;
  final List<M3EMenuNode> overflowMenuEntries;
  final int? pageSize;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;
  final bool filterSortActive;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // 断点跟窗口宽（与 M3 / Viewport addon 一致），不用扣掉水平 padding 后的内容宽。
        final double windowWidth = MediaQuery.sizeOf(context).width;
        final double contentWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : windowWidth;
        final Md3eWindowSizeClass sizeClass =
            Md3eWindowSizeClass.fromWidth(windowWidth);
        final Md3eLibraryPageHeaderLayout layout =
            Md3eLibraryPageHeaderMetrics.layoutFor(sizeClass);
        final bool singleRow =
            layout == Md3eLibraryPageHeaderLayout.singleRowWithTabs;

        final Widget toolbar = _Md3eLibraryPageHeaderToolbar(
          title: title,
          displayTarget: displayTarget,
          sizeClass: sizeClass,
          viewportWidth: contentWidth,
          embedTabs: singleRow,
          onDisplayTargetChanged: onDisplayTargetChanged,
          onFilterSort: onFilterSort,
          overflowMenuEntries: overflowMenuEntries,
          pageSize: pageSize,
          onPageSizeChanged: onPageSizeChanged,
          pageSizeOptions: pageSizeOptions,
          filterSortActive: filterSortActive,
        );

        final Widget? tabsRow = onDisplayTargetChanged == null || singleRow
            ? null
            : _Md3eLibraryDisplayTargetTabs(
                displayTarget: displayTarget,
                sizeClass: sizeClass,
                onChanged: onDisplayTargetChanged!,
              );

        return Padding(
          padding: const EdgeInsets.symmetric(
            vertical: Md3eLibraryPageHeaderMetrics.verticalPadding,
          ),
          child: switch (layout) {
            Md3eLibraryPageHeaderLayout.singleRowWithTabs => toolbar,
            Md3eLibraryPageHeaderLayout.twoRowTabsBelow => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                toolbar,
                if (tabsRow != null) ...<Widget>[
                  const SizedBox(
                    height: Md3eLibraryPageHeaderMetrics.tabsRowTopGap,
                  ),
                  tabsRow,
                ],
              ],
            ),
          },
        );
      },
    );
  }
}

class _Md3eLibraryPageHeaderToolbar extends StatelessWidget {
  const _Md3eLibraryPageHeaderToolbar({
    required this.title,
    required this.displayTarget,
    required this.sizeClass,
    required this.viewportWidth,
    required this.embedTabs,
    this.onDisplayTargetChanged,
    this.onFilterSort,
    this.overflowMenuEntries = const <M3EMenuNode>[],
    this.pageSize,
    this.onPageSizeChanged,
    this.pageSizeOptions = kMd3eLibraryPageSizeOptions,
    this.filterSortActive = false,
  });

  final String title;
  final Md3eLibraryDisplayTarget displayTarget;
  final Md3eWindowSizeClass sizeClass;
  final double viewportWidth;
  final bool embedTabs;
  final ValueChanged<Md3eLibraryDisplayTarget>? onDisplayTargetChanged;
  final VoidCallback? onFilterSort;
  final List<M3EMenuNode> overflowMenuEntries;
  final int? pageSize;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;
  final bool filterSortActive;

  @override
  Widget build(BuildContext context) {
    final M3EThemeData theme = M3ETheme.of(context);
    final M3EColorScheme scheme = theme.colorScheme;
    final M3ETypeScale type = theme.typeScale;

    final Widget leading = Text(
      title,
      style: type.headlineSmall.copyWith(
        fontSize: Md3eLibraryPageHeaderMetrics.titleFontSize(sizeClass),
        fontWeight: Md3eLibraryPageHeaderMetrics.titleFontWeight(sizeClass),
        color: scheme.onSurface,
        letterSpacing: -0.4,
      ),
    );

    final Widget actions = _Md3eLibraryHeaderActions(
      sizeClass: sizeClass,
      filterSortActive: filterSortActive,
      onFilterSort: onFilterSort,
      overflowMenuEntries: overflowMenuEntries,
      pageSize: pageSize,
      onPageSizeChanged: onPageSizeChanged,
      pageSizeOptions: pageSizeOptions,
    );

    final Widget? inlineTabs = embedTabs && onDisplayTargetChanged != null
        ? _Md3eLibraryDisplayTargetTabs(
            displayTarget: displayTarget,
            sizeClass: sizeClass,
            onChanged: onDisplayTargetChanged!,
          )
        : null;

    if (inlineTabs == null) {
      return SizedBox(
        height: Md3eLibraryPageHeaderMetrics.toolbarHeight,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: leading,
              ),
            ),
            actions,
          ],
        ),
      );
    }

    final double tabsMaxWidth =
        Md3eLibraryPageHeaderMetrics.centeredTabsMaxWidth(
          viewportWidth,
          sizeClass,
        );

    return SizedBox(
      height: Md3eLibraryPageHeaderMetrics.toolbarHeight,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: leading,
                ),
              ),
              actions,
            ],
          ),
          SizedBox(
            width: math.min(tabsMaxWidth, viewportWidth),
            child: inlineTabs,
          ),
        ],
      ),
    );
  }
}

class _Md3eLibraryDisplayTargetTabs extends StatelessWidget {
  const _Md3eLibraryDisplayTargetTabs({
    required this.displayTarget,
    required this.sizeClass,
    required this.onChanged,
  });

  final Md3eLibraryDisplayTarget displayTarget;
  final Md3eWindowSizeClass sizeClass;
  final ValueChanged<Md3eLibraryDisplayTarget> onChanged;

  @override
  Widget build(BuildContext context) {
    final int selectedIndex = displayTarget == Md3eLibraryDisplayTarget.comics
        ? 0
        : 1;
    final M3EThemeData theme = M3ETheme.of(context);
    final M3ETabTheme tabTheme =
        Md3eLibraryPageHeaderMetrics.tabThemeFor(sizeClass);

    return M3ETheme(
      data: theme.copyWith(tabTheme: tabTheme),
      child: M3ETabs(
        variant: M3ETabsVariant.secondary,
        alignment: M3ETabsAlignment.fill,
        scrollable: false,
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
    );
  }
}

class _Md3eLibraryHeaderActions extends StatelessWidget {
  const _Md3eLibraryHeaderActions({
    required this.sizeClass,
    required this.filterSortActive,
    this.onFilterSort,
    this.overflowMenuEntries = const <M3EMenuNode>[],
    this.pageSize,
    this.onPageSizeChanged,
    this.pageSizeOptions = kMd3eLibraryPageSizeOptions,
  });

  final Md3eWindowSizeClass sizeClass;
  final bool filterSortActive;
  final VoidCallback? onFilterSort;
  final List<M3EMenuNode> overflowMenuEntries;
  final int? pageSize;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;

  List<M3EMenuNode> _menuChildren() {
    final List<M3EMenuNode> nodes = List<M3EMenuNode>.of(overflowMenuEntries);
    if (onPageSizeChanged != null && pageSize != null) {
      nodes.add(
        M3EMenuSubmenu(
          label: '每页数量',
          leading: Icon(
            Icons.view_module_outlined,
            size: Md3eLibraryPageHeaderMetrics.actionIconSize,
          ),
          children: <M3EMenuNode>[
            for (final int option in pageSizeOptions)
              M3EMenuSelectable(
                label: '$option',
                value: option,
                selected: option == pageSize,
                onPressed: () => onPageSizeChanged!(option),
              ),
          ],
        ),
      );
    }
    return nodes;
  }

  @override
  Widget build(BuildContext context) {
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final double gap = Md3eLibraryPageHeaderMetrics.actionSpacing(sizeClass);
    final Color filterColor =
        filterSortActive ? scheme.primary : scheme.onSurfaceVariant;
    final List<M3EMenuNode> menuChildren = _menuChildren();

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _actionIcon(
          icon: Icons.filter_list,
          tooltip: '筛选与排序',
          color: filterColor,
          onPressed: onFilterSort,
        ),
        SizedBox(width: gap),
        if (menuChildren.isEmpty)
          _actionIcon(
            icon: Icons.more_vert,
            tooltip: '更多',
            onPressed: null,
          )
        else
          Md3eAnchoredMenu(
            position: M3EMenuAnchorPosition.bottomEnd,
            children: menuChildren,
            anchorBuilder: (BuildContext context, VoidCallback open) {
              return _actionIcon(
                icon: Icons.more_vert,
                tooltip: '更多',
                onPressed: open,
              );
            },
          ),
      ],
    );
  }

  Widget _actionIcon({
    required IconData icon,
    required String tooltip,
    Color? color,
    VoidCallback? onPressed,
  }) {
    return M3EIconButton(
      icon: Icon(
        icon,
        size: Md3eLibraryPageHeaderMetrics.actionIconSize,
        color: color,
      ),
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}
