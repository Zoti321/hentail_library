import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/shared/domain/catalog/selection/catalog_selection_notifier.dart';
import 'package:hentai_library/features/comic/public/ui/comic_card_actions.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/features/comic/public/comic.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid.dart';
import 'package:hentai_library/shared/ui/layout/catalog_grid_metrics.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/ui/widgets/catalog/comic_card.dart';
import 'package:material_3_expressive/material_3_expressive.dart';

/// 系列内漫画网格（复用书库 [CatalogGridSliver] 布局）。
class SeriesDetailComicsGrid extends ConsumerWidget {
  const SeriesDetailComicsGrid({
    super.key,
    required this.items,
    this.onComicTap,
  });

  final List<SeriesDetailComicItem> items;
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

    return CatalogGridSliver(
      horizontalMargin: 0,
      itemCount: items.length,
      itemBuilder: (BuildContext context, int index, CatalogGridLayout _) {
        final SeriesDetailComicItem item = items[index];
        final String? subtitle = item.pageCount == null
            ? null
            : l10n.comicDetailPageCount(item.pageCount!);
        final Comic? comic = item.comic;
        final String? comicId = comic?.comicId;
        final Widget card = ComicCard(
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
        return ComicCardActions(
          key: ValueKey<String>(comic.comicId),
          comic: comic,
          enabled: !selectionActive,
          child: card,
        );
      },
    );
  }
}
