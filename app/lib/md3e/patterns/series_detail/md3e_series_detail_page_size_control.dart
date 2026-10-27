import 'package:flutter/material.dart';
import 'package:hentai_library/md3e/l10n/md3e_l10n.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header.dart';
import 'package:hentai_library/md3e/patterns/library/md3e_library_page_header_metrics.dart';
import 'package:hentai_library/md3e/widgets/menu/md3e_anchored_menu.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 系列详情顶栏每页条数（与漫画库溢出菜单中的 page size 子菜单一致）。
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
      children: <M3EMenuNode>[
        for (final int option in pageSizeOptions)
          M3EMenuSelectable(
            label: '$option',
            value: option,
            selected: option == pageSize,
            onPressed: () => onPageSizeChanged(option),
          ),
      ],
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
