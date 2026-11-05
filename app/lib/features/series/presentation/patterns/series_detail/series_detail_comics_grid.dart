import 'package:flutter/material.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail_md3e/series_detail_page_entry.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列内漫画网格（复用书库 [Md3eCatalogGridSliver] 布局）。
class Md3eSeriesDetailComicsGrid extends StatelessWidget {
  const Md3eSeriesDetailComicsGrid({
    super.key,
    required this.items,
    this.onComicTap,
  });

  final List<Md3eSeriesDetailComicItem> items;
  final ValueChanged<int>? onComicTap;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;

    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: Text(
              l10n.seriesDetailNoComics,
              style: M3ETheme.of(context).typeScale.bodySmall
                  .copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return Md3eCatalogGridSliver(
      horizontalMargin: 0,
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index, Md3eCatalogGridLayout _) {
        final Md3eSeriesDetailComicItem item = items[index];
        final String? subtitle = item.pageCount == null
            ? null
            : l10n.comicDetailPageCount(item.pageCount!);
        return Md3eComicCard(
          title: item.title,
          subtitle: subtitle,
          readProgress: item.readProgress,
          cover:
              item.cover ??
              ColoredBox(
                color: scheme.surfaceContainerHigh,
                child: Icon(
                  Icons.image_outlined,
                  color: scheme.onSurfaceVariant,
                ),
              ),
          onTap: () => onComicTap?.call(index),
        );
      },
    );
  }
}
