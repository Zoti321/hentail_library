import 'package:flutter/material.dart';
import 'package:hentai_library/core/l10n/app_localizations.dart';
import 'package:hentai_library/core/l10n/app_localizations_x.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/comic_card.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_page_widgets.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';

class SeriesDetailComicsGridSliver extends StatelessWidget {
  const SeriesDetailComicsGridSliver({
    super.key,
    required this.comics,
    this.isLoading = false,
  });

  final List<Comic> comics;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    // Must return a sliver. LayoutBuilder is a RenderBox and cannot be a
    // SliverPadding / SliverMainAxisGroup child.
    final LibraryLayoutTier layoutTier = libraryLayoutTierForWidth(
      MediaQuery.sizeOf(context).width,
    );
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final SliverGridDelegate gridDelegate = libraryGridDelegateForTokens(
      tokens,
      layoutTier,
    );

    if (isLoading && comics.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl),
          child: const Center(child: CircularProgressIndicator()),
        ),
      );
    }

    final AppLocalizations l10n = context.l10n;
    if (comics.isEmpty) {
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
        final Comic comic = comics[index];
        return Center(
          child: ComicCard(
            key: Key(comic.comicId),
            comic: comic,
            gridIndex: index,
            onTap: () {
              appRouter.pushNamed(
                '漫画详情',
                pathParameters: <String, String>{'id': comic.comicId},
              );
            },
          ),
        );
      }, childCount: comics.length),
    );
  }
}
