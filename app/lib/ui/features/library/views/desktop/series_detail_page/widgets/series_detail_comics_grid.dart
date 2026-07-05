import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/ui/core/theme/theme.dart';
import 'package:hentai_library/ui/core/widgets/element/card/comic_card.dart';
import 'package:hentai_library/ui/features/library/views/desktop/library_page/widgets/library_page_widgets.dart';
import 'package:hentai_library/ui/features/reader/read_session_launcher.dart';
import 'package:hentai_library/ui/features/shell/views/routing/app_router.dart';

class SeriesDetailComicsGrid extends ConsumerWidget {
  const SeriesDetailComicsGrid({
    super.key,
    required this.seriesId,
    required this.sortedItems,
    required this.comicsById,
  });

  final String seriesId;
  final List<SeriesItem> sortedItems;
  final Map<String, Comic> comicsById;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppThemeTokens tokens = context.tokens;
    final ColorScheme cs = Theme.of(context).colorScheme;
    final SliverGridDelegate gridDelegate = libraryGridDelegateForTokens(
      tokens,
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
            size: const Size(double.infinity, double.infinity),
            onTap: () {
              appRouter.pushNamed(
                '漫画详情',
                pathParameters: <String, String>{'id': comic.comicId},
              );
            },
            onPlay: () {
              openReadSession(ref, comicId: comic.comicId, seriesId: seriesId);
            },
          ),
        );
      },
    );
  }
}
