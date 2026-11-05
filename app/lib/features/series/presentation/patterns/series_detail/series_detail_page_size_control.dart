import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:hentai_library/shared/ui/widgets/menu/anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';
import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';

/// 系列详情顶栏每页条数菜单节点（宽屏一级菜单 / 窄屏收进「更多」二级子菜单）。
List<M3EMenuNode> md3eSeriesDetailPageSizeMenuNodes({
  required AppLocalizations l10n,
  required int pageSize,
  required ValueChanged<int> onPageSizeChanged,
  required List<int> pageSizeOptions,
  required bool nestedInMoreMenu,
}) {
  const double iconSize = Md3eLibraryPageHeaderMetrics.actionIconSize;
  final List<M3EMenuNode> options = <M3EMenuNode>[
    for (final int option in pageSizeOptions)
      M3EMenuSelectable(
        label: '$option',
        value: option,
        selected: option == pageSize,
        onPressed: () => onPageSizeChanged(option),
      ),
  ];
  if (!nestedInMoreMenu) {
    return options;
  }
  return <M3EMenuNode>[
    M3EMenuSubmenu(
      label: l10n.libraryPageSizeTooltip,
      leading: Icon(Symbols.grid_view, size: iconSize),
      children: options,
    ),
  ];
}

/// 系列详情顶栏每页条数（expanded+：独立按钮 + 一级可选菜单）。
class Md3eSeriesDetailPageSizeControl extends StatelessWidget {
  const Md3eSeriesDetailPageSizeControl({
    super.key,
    required this.pageSize,
    required this.onPageSizeChanged,
    this.pageSizeOptions = kMd3eLibraryPageSizeOptions,
  });

  final int pageSize;
  final ValueChanged<int> onPageSizeChanged;
  final List<int> pageSizeOptions;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    const double iconSize = Md3eLibraryPageHeaderMetrics.actionIconSize;

    return Md3eAnchoredMenu(
      position: M3EMenuAnchorPosition.bottomEnd,
      children: md3eSeriesDetailPageSizeMenuNodes(
        l10n: l10n,
        pageSize: pageSize,
        onPageSizeChanged: onPageSizeChanged,
        pageSizeOptions: pageSizeOptions,
        nestedInMoreMenu: false,
      ),
      anchorBuilder: (BuildContext context, VoidCallback open) {
        return M3EIconButton(
          icon: Icon(
            Symbols.grid_view,
            size: iconSize,
            color: scheme.onSurfaceVariant,
          ),
          variant: M3EIconButtonVariant.standard,
          size: M3EIconButtonSize.sm,
          tooltip: l10n.libraryPageSizeTooltip,
          semanticLabel: l10n.libraryPageSizeTooltip,
          onPressed: open,
        );
      },
    );
  }
}
