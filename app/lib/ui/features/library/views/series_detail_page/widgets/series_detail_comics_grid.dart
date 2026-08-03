import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_page_widgets.dart';
import 'package:hentai_library/ui/features/library/views/series_detail_page/widgets/series_detail_comic_card.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';

class SeriesDetailComicsGridSliver extends StatelessWidget {
  const SeriesDetailComicsGridSliver({
    super.key,
    required this.seriesId,
    required this.items,
    this.isLoading = false,
  });

  final String seriesId;
  final List<SeriesComicPageItem> items;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final LibraryLayoutTier layoutTier = libraryLayoutTierForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final SliverGridDelegate gridDelegate = libraryGridDelegateForTokens(
      tokens,
      layoutTier,
    );

    if (isLoading && items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final AppLocalizations l10n = context.l10n;
    if (items.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl),
          child: Center(
            child: Text(
              l10n.seriesDetailNoComics,
              style: TextStyle(
                fontSize: tokens.text.bodySm,
                color: cs.hentai.textTertiary,
              ),
            ),
          ),
        ),
      );
    }

    return SliverGrid(
      gridDelegate: gridDelegate,
      delegate: SliverChildBuilderDelegate((BuildContext context, int index) {
        final SeriesComicPageItem item = items[index];
        return Center(
          child: SeriesDetailComicCard(
            key: Key(item.comic.comicId),
            seriesId: seriesId,
            item: item,
            gridIndex: index,
            onTap: () {
              appRouter.pushNamed(
                '漫画详情',
                pathParameters: <String, String>{'id': item.comic.comicId},
              );
            },
          ),
        );
      }, childCount: items.length),
    );
  }
}
