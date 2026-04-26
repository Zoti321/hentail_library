import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/entities.dart' show AppSetting;
import 'package:hentai_library/domain/util/enums.dart';
import 'package:hentai_library/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_page_comics_providers.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_page_series_providers.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_query_intent_notifier.dart';
import 'package:hentai_library/presentation/providers/pages/library/library_series_query.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';
import 'package:hentai_library/presentation/providers/deps/repos.dart';

final librarySearchPageComicsProvider =
    FutureProvider.family<List<Comic>, String>((Ref ref, String keyword) async {
      final String trimmed = keyword.trim();
      if (trimmed.isEmpty) {
        return <Comic>[];
      }
      final List<Comic> matched = await ref.read(comicRepoProvider).searchByKeyword(
        trimmed,
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
      final List<Comic> filtered = matched.where((Comic comic) {
        if (!filter.showR18 && comic.contentRating == ContentRating.r18) {
          return false;
        }
        if (filter.comicIdsExcludedBySeriesMembership?.contains(comic.comicId) ??
            false) {
          return false;
        }
        return true;
      }).toList();
      final List<Comic> sorted = List<Comic>.from(filtered);
      switch (intent.sortOption.field) {
        case LibraryComicSortField.title:
          sorted.sort((Comic a, Comic b) {
            final int result = a.title.compareTo(b.title);
            return intent.sortOption.descending ? -result : result;
          });
          return sorted;
      }
    });

final librarySearchPageSeriesViewDataProvider =
    FutureProvider.family<LibrarySeriesViewData, String>((Ref ref, String keyword) async {
      final String trimmed = keyword.trim();
      if (trimmed.isEmpty) {
        return const LibrarySeriesViewData(
          headerTotalSeriesWithItemsCount: 0,
          seriesWithItemsCount: 0,
          filteredSeries: <Series>[],
        );
      }
      final List<Series> matched = await ref
          .read(librarySeriesRepoProvider)
          .searchByKeyword(trimmed);
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
