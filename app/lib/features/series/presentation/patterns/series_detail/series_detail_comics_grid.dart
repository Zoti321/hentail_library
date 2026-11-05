import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail_md3e/series_detail_page_entry.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列内漫画网格（复用书库 [Md3eCatalogGridSliver] 布局）。
class Md3eSeriesDetailComicsGrid extends ConsumerWidget {
  const Md3eSeriesDetailComicsGrid({
    super.key,
    required this.items,
    this.onComicTap,
  });

  final List<Md3eSeriesDetailComicItem> items;
  final ValueChanged<int>? onComicTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppLocalizations l10n = context.l10n;
    final M3EColorScheme scheme = M3ETheme.of(context).colorScheme;
    final CatalogSelectionState selection = ref.watch(catalogSelectionProvider);
    final bool selectionActive = selection.isSeriesDetailSelection;
    final CatalogSelectionNotifier selectionNotifier = ref.read(
      catalogSelectionProvider.notifier,
    );

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
        final Comic? comic = item.comic;
        final String? comicId = comic?.comicId;
        final Widget card = Md3eComicCard(
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
          selectionMode: selectionActive,
          selected: comicId != null && selection.selectedIds.contains(comicId),
          onSelectionChanged: comicId == null
              ? null
              : (_) => selectionNotifier.toggle(comicId),
          onTap: () {
            if (selectionActive) {
              if (comicId != null) {
                selectionNotifier.toggle(comicId);
              }
              return;
            }
            onComicTap?.call(index);
          },
        );
        if (comic == null) {
          return card;
        }
        return Md3eComicCardActions(
          key: ValueKey<String>(comic.comicId),
          comic: comic,
          enabled: !selectionActive,
          child: card,
        );
      },
    );
  }
}
