export 'md3e_library_display_target.dart';

import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/layout/md3e_breakpoints.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// Default page-size choices for the overflow submenu (Lab).
const List<int> kMd3eLibraryPageSizeOptions = <int>[20, 50, 100, 200];

/// 漫画库粘滞页头：标题 + 操作（与 [Md3eLibraryBrowsePage] 一致）。
///
/// 漫画 / 系列切换在 [Md3eLibraryCatalogToolbar]，随列表滚动，不在本组件内。
class Md3eLibraryPageHeader extends StatelessWidget {
  const Md3eLibraryPageHeader({
    super.key,
    this.title = '漫画库',
    this.onFilterSort,
    this.overflowMenuEntries = const <M3EMenuNode>[],
    this.pageSize,
    this.onPageSizeChanged,
    this.pageSizeOptions = kMd3eLibraryPageSizeOptions,
    this.filterSortActive = false,
  });

  final String title;
  final VoidCallback? onFilterSort;
  final List<M3EMenuNode> overflowMenuEntries;
  final int? pageSize;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;
  final bool filterSortActive;

  @override
  Widget build(BuildContext context) {
    // 断点跟窗口宽（与 M3 / Viewport addon 一致），不用扣掉水平 padding 后的内容宽。
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final Md3eWindowSizeClass sizeClass =
        Md3eWindowSizeClass.fromWidth(windowWidth);

    return Padding(
      padding: const EdgeInsets.only(
        top: Md3eLibraryPageHeaderMetrics.verticalPadding,
        bottom: Md3eLibraryPageHeaderMetrics.browsePinnedHeaderBottomPadding,
      ),
      child: _Md3eLibraryPageHeaderToolbar(
        title: title,
        sizeClass: sizeClass,
        onFilterSort: onFilterSort,
        overflowMenuEntries: overflowMenuEntries,
        pageSize: pageSize,
        onPageSizeChanged: onPageSizeChanged,
        pageSizeOptions: pageSizeOptions,
        filterSortActive: filterSortActive,
      ),
    );
  }
}

class _Md3eLibraryPageHeaderToolbar extends StatelessWidget {
  const _Md3eLibraryPageHeaderToolbar({
    required this.title,
    required this.sizeClass,
    this.onFilterSort,
    this.overflowMenuEntries = const <M3EMenuNode>[],
    this.pageSize,
    this.onPageSizeChanged,
    this.pageSizeOptions = kMd3eLibraryPageSizeOptions,
    this.filterSortActive = false,
  });

  final String title;
  final Md3eWindowSizeClass sizeClass;
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
