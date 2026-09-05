import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_series_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_query_parser.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'library_search_page_providers.g.dart';

/// 搜索结果区默认每页条数（水平虚拟列表按页追加）。
const int kLibrarySearchPageSize = 40;

typedef LibrarySearchVocabulary = ({
  Set<String> tags,
  Set<String> authors,
  Set<String> parodies,
  Set<String> characters,
  Set<String> languages,
});

typedef LibrarySearchComicsPage = ({
  List<Comic> items,
  int totalCount,
  bool hasMore,
  bool loadingMore,
});

/// Vocabulary keepAlive：避免每次改 query 全表 listAll。
@Riverpod(keepAlive: true)
Future<LibrarySearchVocabulary> librarySearchVocabulary(Ref ref) async {
  final String? libraryId = ref
      .watch(currentLibraryProvider)
      .asData
      ?.value
      .currentId;
  final List<Tag> tags = await ref.read(tagRepoProvider).listAll();
  final List<Author> authors = await ref.read(authorRepoProvider).listAll();
  final List<String> parodies = await ref
      .read(parodyRepoProvider)
      .listDistinct(libraryId: libraryId);
  final List<String> characters = await ref
      .read(characterRepoProvider)
      .listDistinct(libraryId: libraryId);
  return (
    tags: tags.map((Tag t) => t.name).toSet(),
    authors: authors.map((Author a) => a.name).toSet(),
    parodies: parodies.toSet(),
    characters: characters.toSet(),
    languages: ComicLanguageNames.closedSet.toSet(),
  );
}

LibrarySearchQuery _parse(String trimmed, LibrarySearchVocabulary vocabulary) {
  return parseLibrarySearchQuery(
    trimmed,
    knownTagNames: vocabulary.tags,
    knownAuthorNames: vocabulary.authors,
    knownParodyNames: vocabulary.parodies,
    knownCharacterNames: vocabulary.characters,
    knownLanguageNames: vocabulary.languages,
  );
}

@Riverpod()
class LibrarySearchPageComicsController
    extends _$LibrarySearchPageComicsController {
  int _loadedPage = 0;
  LibrarySearchQuery? _query;

  @override
  Future<LibrarySearchComicsPage> build(String keyword) async {
    final String trimmed = keyword.trim();
    if (trimmed.isEmpty) {
      _loadedPage = 0;
      _query = null;
      return (
        items: const <Comic>[],
        totalCount: 0,
        hasMore: false,
        loadingMore: false,
      );
    }
    final LibrarySearchVocabulary vocabulary = await ref.watch(
      librarySearchVocabularyProvider.future,
    );
    _query = _parse(trimmed, vocabulary);
    _loadedPage = 1;
    final PagedResult<Comic> page = await _fetchPage(1);
    return (
      items: page.items,
      totalCount: page.totalCount,
      hasMore: page.hasNextPage,
      loadingMore: false,
    );
  }

  Future<void> loadMore() async {
    final LibrarySearchComicsPage? current = state.asData?.value;
    if (current == null || !current.hasMore || current.loadingMore) {
      return;
    }
    state = AsyncData((
      items: current.items,
      totalCount: current.totalCount,
      hasMore: current.hasMore,
      loadingMore: true,
    ));
    try {
      final int nextPage = _loadedPage + 1;
      final PagedResult<Comic> page = await _fetchPage(nextPage);
      _loadedPage = nextPage;
      final List<Comic> merged = <Comic>[...current.items, ...page.items];
      state = AsyncData((
        items: merged,
        totalCount: page.totalCount,
        hasMore: page.hasNextPage,
        loadingMore: false,
      ));
    } on Object catch (error, stackTrace) {
      state = AsyncError(error, stackTrace);
    }
  }

  Future<PagedResult<Comic>> _fetchPage(int page) {
    final LibrarySearchQuery query = _query!;
    final PageRequest request = pageRequest(
      page: page,
      pageSize: kLibrarySearchPageSize,
    );
    return switch (query) {
      LibrarySearchKeywordQuery(:final keyword) =>
        ref
            .read(comicRepoProvider)
            .searchByKeywordPage(keyword: keyword, request: request),
      LibrarySearchMetadataQuery(
        :final mustInclude,
        :final optionalOr,
        :final mustExclude,
      ) =>
        ref
            .read(comicRepoProvider)
            .searchByMetadataExpressionPage(
              mustInclude: mustInclude,
              optionalOr: optionalOr,
              mustExclude: mustExclude,
              request: request,
            ),
    };
  }
}

@Riverpod()
Future<LibrarySeriesViewData> librarySearchPageSeriesViewData(
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
  final LibrarySearchVocabulary vocabulary = await ref.watch(
    librarySearchVocabularyProvider.future,
  );
  final LibrarySearchQuery query = _parse(trimmed, vocabulary);
  final List<Series> matched = switch (query) {
    LibrarySearchKeywordQuery(:final keyword) =>
      await ref.read(seriesRepoProvider).searchByKeyword(keyword),
    LibrarySearchMetadataQuery(
      :final mustInclude,
      :final optionalOr,
      :final mustExclude,
    ) =>
      await ref
          .read(seriesRepoProvider)
          .searchByMetadataExpression(
            mustInclude: mustInclude,
            optionalOr: optionalOr,
            mustExclude: mustExclude,
          ),
  };
  return LibrarySeriesViewData(
    headerTotalSeriesWithItemsCount: matched.length,
    seriesWithItemsCount: matched.length,
    filteredSeries: matched,
  );
}
