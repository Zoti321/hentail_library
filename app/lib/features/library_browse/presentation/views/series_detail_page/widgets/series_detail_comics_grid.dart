import 'package:flutter/material.dart';
import 'package:hentai_library/shared/core/l10n/app_localizations.dart';
import 'package:hentai_library/shared/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/shared/ui/theme/theme.dart';
import 'package:hentai_library/features/library_browse/presentation/view_models/comic_detail_return_series_notifier.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_page_widgets.dart';
import 'package:hentai_library/features/library_browse/presentation/views/series_detail_page/widgets/series_detail_comic_card.dart';
import 'package:hentai_library/shared/core/constants/content_routes.dart';
import 'package:hentai_library/shared/di/app_router_provider.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

class SeriesDetailComicsGridSliver extends ConsumerWidget {
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
  Widget build(BuildContext context, WidgetRef ref) {
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
              ref
                  .read(comicDetailReturnSeriesProvider.notifier)
                  .remember(seriesId);
              ref
                  .read(appRouterProvider)
                  .pushNamed(
                    ContentRoutes.comicDetail,
                    pathParameters: <String, String>{'id': item.comic.comicId},
                  );
            },
          ),
        );
      }, childCount: items.length),
    );
  }
}
