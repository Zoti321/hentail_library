import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/comic/presentation/patterns/comic_detail/comic_detail_series_catalog_sheet.dart';
import 'package:hentai_library/shared/ui/patterns/library/library_page_header_metrics.dart';
import 'package:material_3_expressive/material_3_expressive.dart';
import 'package:material_symbols_icons/symbols.dart';

/// 系列目录图标：点击打开 bottom sheet 选卷（全断点）。
class ComicDetailSeriesNav extends StatelessWidget {
  const ComicDetailSeriesNav({
    super.key,
    required this.catalog,
    required this.currentIndex,
    this.onSelectIndex,
  });

  final List<String> catalog;
  final int currentIndex;
  final ValueChanged<int>? onSelectIndex;

  void _openCatalogSheet(BuildContext context) {
    ComicDetailSeriesCatalogSheet.show(
      context,
      catalog: catalog,
      currentIndex: currentIndex,
      onSelectIndex: (int index) => onSelectIndex?.call(index),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    const double iconSize = LibraryPageHeaderMetrics.actionIconSize;
    final bool enabled = catalog.isNotEmpty;

    return M3EIconButton(
      icon: Icon(
        Symbols.list_alt,
        size: iconSize,
        color: enabled
            ? scheme.onSurfaceVariant
            : scheme.onSurface.withValues(alpha: 0.38),
      ),
      variant: M3EIconButtonVariant.standard,
      size: M3EIconButtonSize.sm,
      tooltip: l10n.comicDetailSeriesCatalog,
      semanticLabel: l10n.comicDetailSeriesCatalog,
      onPressed: enabled ? () => _openCatalogSheet(context) : null,
    );
  }
}
