import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_series_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_query_parser.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';

final librarySearchPageComicsProvider =
    FutureProvider.family<List<Comic>, String>((Ref ref, String keyword) async {
      final String trimmed = keyword.trim();
      if (trimmed.isEmpty) {
        return <Comic>[];
      }
      final TagSearchExpression? tagExpression = parsePureTagSearchExpression(
        trimmed,
      );
      if (tagExpression == null) {
        return ref.read(comicRepoProvider).searchByKeyword(trimmed);
      }
      return ref
          .read(comicRepoProvider)
          .searchByTagExpression(
            mustInclude: tagExpression.mustInclude,
            optionalOr: tagExpression.optionalOr,
            mustExclude: tagExpression.mustExclude,
          );
    });

final librarySearchPageSeriesViewDataProvider =
    FutureProvider.family<LibrarySeriesViewData, String>((
      Ref ref,
      String keyword,
    ) async {
      final String trimmed = keyword.trim();
      if (trimmed.isEmpty) {
        return const LibrarySeriesViewData(
          headerTotalSeriesWithItemsCount: 0,
          seriesWithItemsCount: 0,
          filteredSeries: <Series>[],
        );
      }
      final TagSearchExpression? tagExpression = parsePureTagSearchExpression(
        trimmed,
      );
      final List<Series> matched = tagExpression == null
          ? await ref.read(librarySeriesRepoProvider).searchByKeyword(trimmed)
          : await ref
                .read(librarySeriesRepoProvider)
                .searchByTagExpression(
                  mustInclude: tagExpression.mustInclude,
                  optionalOr: tagExpression.optionalOr,
                  mustExclude: tagExpression.mustExclude,
                );
      return LibrarySeriesViewData(
        headerTotalSeriesWithItemsCount: matched.length,
        seriesWithItemsCount: matched.length,
        filteredSeries: matched,
      );
    });
