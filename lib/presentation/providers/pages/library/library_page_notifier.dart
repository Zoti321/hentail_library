import 'dart:async';

import 'package:collection/collection.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/entity/comic/library_comic.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/extensions/library_comic_extensions.dart';
import 'package:hentai_library/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/domain/value_objects/library_comic_sort_option.dart';
import 'package:hentai_library/domain/value_objects/library_tag_pick.dart';
import 'package:hentai_library/presentation/providers/deps/deps.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_page_notifier.g.dart';

class LibraryPageState {
  LibraryPageState({
    this.rawList = const [],
    this.hasReceivedFirstEmit = false,
    this.streamError,
    LibraryComicFilter? filter,
    LibraryComicSortOption? sortOption,
    this.mergeSearchQuery = '',
    this.isGridView = true,
  })  : filter = filter ?? LibraryComicFilter(showR18: false),
        sortOption = sortOption ?? LibraryComicSortOption();

  final List<LibraryComic> rawList;
  final bool hasReceivedFirstEmit;
  final Object? streamError;
  final LibraryComicFilter filter;
  final LibraryComicSortOption sortOption;
  final String mergeSearchQuery;
  final bool isGridView;

  List<LibraryComic> get displayedComics =>
      rawList.applyFilter(filter).sortedWith(sortOption);

  AsyncValue<List<LibraryComic>> get comicsAsyncValue {
    if (streamError != null) {
      return AsyncValue.error(streamError!, StackTrace.current);
    }
    if (!hasReceivedFirstEmit) {
      return const AsyncValue.loading();
    }
    return AsyncValue.data(displayedComics);
  }

  /// 未筛选的原始列表（首页「最近添加」等）
  AsyncValue<List<LibraryComic>> get rawComicsAsyncValue {
    if (streamError != null) {
      return AsyncValue.error(streamError!, StackTrace.current);
    }
    if (!hasReceivedFirstEmit) {
      return const AsyncValue.loading();
    }
    return AsyncValue.data(rawList);
  }

  List<LibraryTagPick> get libraryTagsForFilter {
    final tags = <LibraryTagPick>[];
    final seen = <String>{};
    for (final c in rawList) {
      for (final t in c.tags) {
        final key = t.name;
        if (seen.contains(key)) continue;
        seen.add(key);
        tags.add(LibraryTagPick(name: t.name));
      }
    }
    tags.sort((a, b) => a.name.compareTo(b.name));
    return tags;
  }

  LibraryPageState copyWith({
    List<LibraryComic>? rawList,
    bool? hasReceivedFirstEmit,
    Object? streamError = _sentinel,
    LibraryComicFilter? filter,
    LibraryComicSortOption? sortOption,
    String? mergeSearchQuery,
    bool? isGridView,
  }) {
    return LibraryPageState(
      rawList: rawList ?? this.rawList,
      hasReceivedFirstEmit: hasReceivedFirstEmit ?? this.hasReceivedFirstEmit,
      streamError: identical(streamError, _sentinel)
          ? this.streamError
          : streamError,
      filter: filter ?? this.filter,
      sortOption: sortOption ?? this.sortOption,
      mergeSearchQuery: mergeSearchQuery ?? this.mergeSearchQuery,
      isGridView: isGridView ?? this.isGridView,
    );
  }

  static const Object _sentinel = Object();
}

@Riverpod(keepAlive: true)
class LibraryPageNotifier extends _$LibraryPageNotifier {
  StreamSubscription<List<LibraryComic>>? _sub;
  Timer? _filterQueryDebounce;
  Timer? _mergeSearchDebounce;

  @override
  LibraryPageState build() {
    final repo = ref.read(libraryComicRepoProvider);
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
    ref.onDispose(() {
      _sub?.cancel();
      _filterQueryDebounce?.cancel();
      _mergeSearchDebounce?.cancel();
    });
    return LibraryPageState();
  }

  void refreshStream() {
    _sub?.cancel();
    final repo = ref.read(libraryComicRepoProvider);
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

  void updateFilterQuery(String? query) {
    _filterQueryDebounce?.cancel();
    _filterQueryDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(filter: state.filter.copyWith(query: query));
    });
  }

  void toggleR18(bool show) {
    state = state.copyWith(filter: state.filter.copyWith(showR18: show));
  }

  void updateTags(Set<LibraryTagPick> tags) {
    state = state.copyWith(filter: state.filter.copyWith(tagsAll: tags));
  }

  void updateTagsAny(Set<LibraryTagPick> tagsAny) {
    state = state.copyWith(filter: state.filter.copyWith(tagsAny: tagsAny));
  }

  void updateTagsExclude(Set<LibraryTagPick> tagsExclude) {
    state = state.copyWith(filter: state.filter.copyWith(tagsExclude: tagsExclude));
  }

  void updateTagFilter({
    Set<LibraryTagPick>? tags,
    Set<LibraryTagPick>? tagsAny,
    Set<LibraryTagPick>? tagsExclude,
  }) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        tagsAll: tags,
        tagsAny: tagsAny,
        tagsExclude: tagsExclude,
      ),
    );
  }

  void updateResourceTypes(Set<ResourceType> types) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        resourceTypes: types.isEmpty ? null : types,
      ),
    );
  }

  void updateContentRatings(Set<ContentRating> ratings) {
    state = state.copyWith(
      filter: state.filter.copyWith(
        contentRatings: ratings.isEmpty ? null : ratings,
      ),
    );
  }

  void resetFilter() {
    state = state.copyWith(filter: LibraryComicFilter(showR18: false));
  }

  void toggleSortDescending(bool descending) {
    state = state.copyWith(
      sortOption: state.sortOption.copyWith(descending: descending),
    );
  }

  void updateSortField(LibraryComicSortField field) {
    state = state.copyWith(sortOption: state.sortOption.copyWith(field: field));
  }

  void resetSortOption() {
    state = state.copyWith(sortOption: LibraryComicSortOption());
  }

  void updateMergeSearch(String value) {
    _mergeSearchDebounce?.cancel();
    _mergeSearchDebounce = Timer(const Duration(milliseconds: 300), () {
      state = state.copyWith(mergeSearchQuery: value);
    });
  }

  void setGridView(bool value) {
    state = state.copyWith(isGridView: value);
  }

  LibraryComic? comicById(String id) {
    return state.rawList.firstWhereOrNull((c) => c.comicId == id);
  }
}

@riverpod
Future<List<LibraryComic>> filteredMergeComics(
  Ref ref, {
  required String comicId,
}) async {
  final page = ref.watch(libraryPageProvider);
  final query = page.mergeSearchQuery;
  final comics = page.rawList.where((e) => e.comicId != comicId).toList();
  if (query.isEmpty) return comics;

  var didDispose = false;
  ref.onDispose(() => didDispose = true);
  await Future.delayed(const Duration(milliseconds: 500));
  if (didDispose) throw Exception('Cancelled');

  return comics
      .where((e) => e.title.toLowerCase().contains(query.toLowerCase()))
      .toList();
}
