import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/series.dart';
import 'package:hentai_library/model/models.dart' show AppSetting;
import 'package:hentai_library/module/comic_list_query/comic_list_query.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_page_comics_providers.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_page_series_providers.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_search_query_parser.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_series_query.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';
import 'package:hentai_library/presentation/providers/deps/repos.dart';
import 'package:hentai_library/presentation/providers/deps/tools.dart';

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
      final bool showR18 = !ref.read(
        settingsProvider.select(
          (AsyncValue<AppSetting> async) =>
              async.asData?.value.isHealthyMode ?? false,
        ),
      );
      final bool hideComicsInSeries = ref.read(
        settingsProvider.select(
          (AsyncValue<AppSetting> async) =>
              async.asData?.value.libraryHideComicsInSeries ?? false,
        ),
      );
      final Set<String> seriesComicIds = ref.read(
        libraryComicIdsInAnySeriesProvider,
      );
      final LibraryComicFilter filter = intent
          .buildBaseFilter(showR18: showR18)
          .copyWith(
            comicIdsExcludedBySeriesMembership: hideComicsInSeries
                ? seriesComicIds
                : null,
          );
      return ref.read(comicListQueryModuleProvider).apply(
        comics: matched,
        filter: filter,
        sortOption: intent.sortOption,
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
      final List<Comic> rawComics = await ref.read(comicRepoProvider).getAll();
      final bool showR18 = !ref.read(
        settingsProvider.select(
          (AsyncValue<AppSetting> async) =>
              async.asData?.value.isHealthyMode ?? false,
        ),
      );
      final LibraryQueryIntent intent = ref.read(libraryQueryIntentProvider);
      final Map<String, Comic> comicsById = <String, Comic>{
        for (final Comic comic in rawComics) comic.comicId: comic,
      };
      final LibrarySeriesQueryResult result = LibrarySeriesQuery(
        showR18: showR18,
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
