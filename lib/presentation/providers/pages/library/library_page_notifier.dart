import 'dart:async';

import 'package:collection/collection.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:hentai_library/domain/util/comic_query.dart';
import 'package:hentai_library/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/library_display_target.dart';
import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:hentai_library/presentation/providers/pages/settings/settings_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../../domain/entity/entities.dart' show AppSetting;

part 'library_page_notifier.freezed.dart';
part 'library_page_notifier.g.dart';

@freezed
abstract class LibraryPageState with _$LibraryPageState {
  const factory LibraryPageState({
    @Default(<Comic>[]) List<Comic> rawList,
    @Default(false) bool hasReceivedFirstEmit,
    Object? streamError,
    LibraryComicFilter? filter,
    LibraryComicSortOption? sortOption,
    @Default('') String mergeSearchQuery,
    @Default(true) bool isGridView,
  }) = _LibraryPageState;

  const LibraryPageState._();

  LibraryComicFilter get effectiveFilter =>
      filter ?? LibraryComicFilter(showR18: true);

  LibraryComicSortOption get effectiveSortOption =>
      sortOption ?? LibraryComicSortOption();
}

extension LibraryPageStateDerived on LibraryPageState {
  List<Comic> get displayedComics => ComicQuery(
    filter: effectiveFilter,
    sortOption: effectiveSortOption,
  ).apply(rawList);

  AsyncValue<List<Comic>> get comicsAsyncValue {
    if (streamError != null) {
      return AsyncValue.error(streamError!, StackTrace.current);
    }
    if (!hasReceivedFirstEmit) {
      return const AsyncValue.loading();
    }
    return AsyncValue.data(displayedComics);
  }

  AsyncValue<List<Comic>> get rawComicsAsyncValue {
    if (streamError != null) {
      return AsyncValue.error(streamError!, StackTrace.current);
    }
    if (!hasReceivedFirstEmit) {
      return const AsyncValue.loading();
    }
    return AsyncValue.data(rawList);
  }
}

@Riverpod(keepAlive: true)
class LibraryPageNotifier extends _$LibraryPageNotifier {
  static const _filterDebounceDuration = Duration(milliseconds: 300);
  static const _mergeSearchDebounceDuration = Duration(milliseconds: 500);

  StreamSubscription<List<Comic>>? _sub;
  Timer? _filterQueryDebounce;
  Timer? _mergeSearchDebounce;

  @override
  LibraryPageState build() {
    ref.listen<AsyncValue<AppSetting>>(settingsProvider, (prev, next) {
      next.whenData((settings) {
        final showR18 = !settings.isHealthyMode;
        if (state.effectiveFilter.showR18 == showR18) return;
        state = state.copyWith(
          filter: state.effectiveFilter.copyWith(showR18: showR18),
        );
      });
    });

    _subscribeLibraryStream();

    ref.onDispose(() {
      _sub?.cancel();
      _filterQueryDebounce?.cancel();
      _mergeSearchDebounce?.cancel();
    });

    return const LibraryPageState();
  }

  void _subscribeLibraryStream() {
    final repo = ref.read(comicRepoProvider);
    _sub = repo.watchAll().listen(
      (list) {
        state = state.copyWith(
          rawList: list,
          hasReceivedFirstEmit: true,
          streamError: null,
        );
      },
      onError: (Object e, StackTrace st) {
        state = state.copyWith(streamError: e, hasReceivedFirstEmit: true);
      },
    );
  }

  void refreshStream() {
    _sub?.cancel();
    _subscribeLibraryStream();
  }

  void _debounceFilter(void Function() action) {
    _filterQueryDebounce?.cancel();
    _filterQueryDebounce = Timer(_filterDebounceDuration, action);
  }

  void _debounceMergeSearch(void Function() action) {
    _mergeSearchDebounce?.cancel();
    _mergeSearchDebounce = Timer(_mergeSearchDebounceDuration, action);
  }

  // Filter APIs
  void updateFilterQuery(String? query) {
    _debounceFilter(() {
      state = state.copyWith(
        filter: state.effectiveFilter.copyWith(query: query),
      );
    });
  }

  void toggleR18() {
    state = state.copyWith(
      filter: state.effectiveFilter.copyWith(
        showR18: !state.effectiveFilter.showR18,
      ),
    );
  }

  void updateResourceTypes(Set<ResourceType> types) {
    state = state.copyWith(
      filter: state.effectiveFilter.copyWith(
        resourceTypes: types.isEmpty ? null : types,
      ),
    );
  }

  void updateContentRatings(Set<ContentRating> ratings) {
    state = state.copyWith(
      filter: state.effectiveFilter.copyWith(
        contentRatings: ratings.isEmpty ? null : ratings,
      ),
    );
  }

  void updateDisplayTarget(LibraryDisplayTarget target) {
    state = state.copyWith(
      filter: state.effectiveFilter.copyWith(displayTarget: target),
    );
  }

  void resetFilter() {
    state = state.copyWith(filter: LibraryComicFilter(showR18: true));
  }

  // Sort APIs
  void toggleSortDescending(bool descending) {
    state = state.copyWith(
      sortOption: state.effectiveSortOption.copyWith(descending: descending),
    );
  }

  void updateSortField(LibraryComicSortField field) {
    state = state.copyWith(
      sortOption: state.effectiveSortOption.copyWith(field: field),
    );
  }

  void resetSortOption() {
    state = state.copyWith(sortOption: LibraryComicSortOption());
  }

  void updateMergeSearch(String value) {
    _debounceMergeSearch(() {
      state = state.copyWith(mergeSearchQuery: value);
    });
  }

  void setGridView(bool value) {
    state = state.copyWith(isGridView: value);
  }

  Comic? comicById(String id) {
    return state.rawList.firstWhereOrNull((c) => c.comicId == id);
  }
}

@riverpod
Future<List<Comic>> filteredMergeComics(
  Ref ref, {
  required String comicId,
}) async {
  final page = ref.watch(libraryPageProvider);
  final query = page.mergeSearchQuery;
  final comics = page.rawList.where((e) => e.comicId != comicId).toList();
  if (query.isEmpty) return comics;

  return comics
      .where((e) => e.title.toLowerCase().contains(query.toLowerCase()))
      .toList();
}
