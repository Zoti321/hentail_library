import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/design-system/design_system.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:hentai_library/shared/ui/patterns/shared/page_title.dart';
import 'package:hentai_library/shared/ui/patterns/shared/pinned_toolbar_chrome.dart';
import 'package:hentai_library/shared/domain/catalog/page_size/library_tab_page_size_settings.dart'
    show kLibraryPageSizeOptions;
import 'package:hentai_library/shared/ui/widgets/menu/anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 漫画库粘滞页头：标题 + 操作（与 [LibraryBrowseLayout] 一致）。
///
/// 漫画 / 系列切换在 [LibraryCatalogToolbar]，随列表滚动，不在本组件内。
class LibraryPageHeader extends StatelessWidget {
  const LibraryPageHeader({
    super.key,
    this.title,
    this.onFilterSort,
    this.overflowMenuEntries = const <M3EMenuNode>[],
    this.pageSize,
    this.onPageSizeChanged,
    this.pageSizeOptions = kLibraryPageSizeOptions,
    this.filterSortActive = false,
  });

  /// Defaults to [AppLocalizations.libraryTitle] when null.
  final String? title;
  final VoidCallback? onFilterSort;
  final List<M3EMenuNode> overflowMenuEntries;
  final int? pageSize;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;
  final bool filterSortActive;

  @override
  Widget build(BuildContext context) {
    // 断点取页面视口宽度（已扣除 shell 侧栏），与其他页面的 PageLayoutSpec 保持一致。
    final WindowSizeClass sizeClass = PageLayoutSpec.of(context).sizeClass;

    return PinnedToolbarChrome(
      child: _LibraryPageHeaderToolbar(
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

class _LibraryPageHeaderToolbar extends StatelessWidget {
  const _LibraryPageHeaderToolbar({
    required this.title,
    required this.sizeClass,
    this.onFilterSort,
    this.overflowMenuEntries = const <M3EMenuNode>[],
    this.pageSize,
    this.onPageSizeChanged,
    this.pageSizeOptions = kLibraryPageSizeOptions,
    this.filterSortActive = false,
  });

  /// Defaults to [AppLocalizations.libraryTitle] when null.
  final String? title;
  final WindowSizeClass sizeClass;
  final VoidCallback? onFilterSort;
  final List<M3EMenuNode> overflowMenuEntries;
  final int? pageSize;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;
  final bool filterSortActive;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final Widget leading = PageTitle(title ?? l10n.libraryTitle);

    final Widget actions = _LibraryHeaderActions(
      sizeClass: sizeClass,
      filterSortActive: filterSortActive,
      onFilterSort: onFilterSort,
      overflowMenuEntries: overflowMenuEntries,
      pageSize: pageSize,
      onPageSizeChanged: onPageSizeChanged,
      pageSizeOptions: pageSizeOptions,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Expanded(
          child: Align(alignment: Alignment.centerLeft, child: leading),
        ),
        actions,
      ],
    );
  }
}

class _LibraryHeaderActions extends StatelessWidget {
  const _LibraryHeaderActions({
    required this.sizeClass,
    required this.filterSortActive,
    this.onFilterSort,
    this.overflowMenuEntries = const <M3EMenuNode>[],
    this.pageSize,
    this.onPageSizeChanged,
    this.pageSizeOptions = kLibraryPageSizeOptions,
  });

  final WindowSizeClass sizeClass;
  final bool filterSortActive;
  final VoidCallback? onFilterSort;
  final List<M3EMenuNode> overflowMenuEntries;
  final int? pageSize;
  final ValueChanged<int>? onPageSizeChanged;
  final List<int> pageSizeOptions;

  List<M3EMenuNode> _menuChildren(AppLocalizations l10n) {
    final List<M3EMenuNode> nodes = List<M3EMenuNode>.of(overflowMenuEntries);
    if (onPageSizeChanged != null && pageSize != null) {
      nodes.add(
        M3EMenuSubmenu(
          label: l10n.libraryPageSizeTooltip,
          leading: Icon(
            Icons.view_module_outlined,
            size: LibraryPageHeaderMetrics.actionIconSize,
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
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final double gap = LibraryPageHeaderMetrics.actionSpacing(sizeClass);
    final Color filterColor = filterSortActive
        ? scheme.primary
        : scheme.onSurfaceVariant;
    final List<M3EMenuNode> menuChildren = _menuChildren(l10n);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        _actionIcon(
          icon: Icons.filter_list,
          tooltip: l10n.libraryFilterSortTooltip,
          semanticLabel: l10n.libraryFilterSortSemantic,
          color: filterColor,
          onPressed: onFilterSort,
        ),
        SizedBox(width: gap),
        if (menuChildren.isEmpty)
          _actionIcon(
            icon: Icons.more_vert,
            tooltip: l10n.metadataMoreActions,
            onPressed: null,
          )
        else
          AnchoredMenu(
            position: M3EMenuAnchorPosition.bottomEnd,
            children: menuChildren,
            anchorBuilder: (BuildContext context, VoidCallback open) {
              return _actionIcon(
                icon: Icons.more_vert,
                tooltip: l10n.metadataMoreActions,
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
    String? semanticLabel,
    Color? color,
    VoidCallback? onPressed,
  }) {
    return M3EIconButton(
      icon: Icon(
        icon,
        size: LibraryPageHeaderMetrics.actionIconSize,
        color: color,
      ),
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      tooltip: tooltip,
      semanticLabel: semanticLabel ?? tooltip,
      onPressed: onPressed,
    );
  }
}
