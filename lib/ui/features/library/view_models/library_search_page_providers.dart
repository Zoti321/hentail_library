import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/library/comic_list_query.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_comics_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_series_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent.dart';
import 'package:hentai_library/ui/features/library/view_models/library_query_intent_notifier.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_query_parser.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_query.dart';
import 'package:hentai_library/ui/features/library/view_models/library_view_settings_providers.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';

const LibraryComicProjection _libraryComicProjection = LibraryComicProjection();

final librarySearchPageComicsProvider =
    FutureProvider.family<List<Comic>, String>((Ref ref, String keyword) async {
      final String trimmed = keyword.trim();
      if (trimmed.isEmpty) {
        return <Comic>[];
      }
      final TagSearchExpression? tagExpression = parsePureTagSearchExpression(
        trimmed,
      );
      final List<Comic> matched = tagExpression == null
          ? await ref.read(comicRepoProvider).searchByKeyword(trimmed)
          : await ref
                .read(comicRepoProvider)
                .searchByTagExpression(
                  mustInclude: tagExpression.mustInclude,
                  optionalOr: tagExpression.optionalOr,
                  mustExclude: tagExpression.mustExclude,
                );
      final LibraryQueryIntent intent = ref.read(libraryQueryIntentProvider);
      final LibraryViewSettings viewSettings = ref.read(
        libraryViewSettingsProvider,
      );
      final Set<String> seriesComicIds = ref.read(
        libraryComicIdsInAnySeriesProvider,
      );
      final LibraryComicFilter filter = _libraryComicProjection.buildListFilter(
        displayTarget: intent.displayTarget,
        isHealthyMode: viewSettings.isHealthyMode,
        hideComicsInSeries: viewSettings.hideComicsInSeries,
        comicIdsInAnySeries: seriesComicIds,
      );
      return ComicQuery(
        filter: filter,
        sortOption: intent.sortOption,
      ).apply(matched);
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
      final List<Comic> rawComics = await ref.read(comicRepoProvider).getAll();
      final LibraryViewSettings viewSettings = ref.read(
        libraryViewSettingsProvider,
      );
      final LibraryQueryIntent intent = ref.read(libraryQueryIntentProvider);
      final Map<String, Comic> comicsById = <String, Comic>{
        for (final Comic comic in rawComics) comic.comicId: comic,
      };
      final LibrarySeriesQueryResult result = LibrarySeriesQuery(
        showR18: _libraryComicProjection.showR18(
          isHealthyMode: viewSettings.isHealthyMode,
        ),
        query: '',
        sortOption: intent.sortOption,
        comicsById: comicsById,
      ).apply(matched);
      return LibrarySeriesViewData(
        headerTotalSeriesWithItemsCount: result.headerTotalSeriesWithItemsCount,
        seriesWithItemsCount: result.seriesWithItemsCount,
        filteredSeries: result.filteredSeries,
      );
    });
