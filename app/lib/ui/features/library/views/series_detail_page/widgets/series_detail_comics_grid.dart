import 'package:flutter/material.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/comic_card.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_page_widgets.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';

class SeriesDetailComicsGrid extends StatelessWidget {
  const SeriesDetailComicsGrid({
    super.key,
    required this.sortedItems,
    required this.comicsById,
  });

  final List<SeriesItem> sortedItems;
  final Map<String, Comic> comicsById;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final LibraryLayoutTier layoutTier = libraryLayoutTierForWidth(
          constraints.maxWidth,
        );
        final AppThemeTokens tokens = context.tokens;
        final ColorScheme cs = Theme.of(context).colorScheme;
        final SliverGridDelegate gridDelegate = libraryGridDelegateForTokens(
          tokens,
          layoutTier,
        );
        final List<Comic> orderedComics = <Comic>[];
        for (final SeriesItem item in sortedItems) {
          final Comic? comic = comicsById[item.comicId];
          if (comic != null) {
            orderedComics.add(comic);
          }
        }

        if (orderedComics.isEmpty) {
          return Padding(
            padding: EdgeInsets.symmetric(vertical: tokens.spacing.xl),
            child: Center(
              child: Text(
                '系列内暂无漫画',
                style: TextStyle(
                  fontSize: tokens.text.bodySm,
                  color: cs.hentai.textTertiary,
                ),
              ),
            ),
          );
        }

        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: gridDelegate,
          itemCount: orderedComics.length,
          itemBuilder: (BuildContext context, int index) {
            final Comic comic = orderedComics[index];
            return Center(
              child: ComicCard(
                key: Key(comic.comicId),
                comic: comic,
                onTap: () {
                  appRouter.pushNamed(
                    '漫画详情',
                    pathParameters: <String, String>{'id': comic.comicId},
                  );
                },
              ),
            );
          },
        );
      },
    );
  }
}
