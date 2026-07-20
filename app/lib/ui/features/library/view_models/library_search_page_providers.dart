import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_series_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_query_parser.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';

typedef _SearchVocabulary = ({Set<String> tags, Set<String> authors});

Future<_SearchVocabulary> _loadSearchVocabulary(Ref ref) async {
  final List<Tag> tags = await ref.read(tagRepoProvider).listAll();
  final List<Author> authors = await ref.read(authorRepoProvider).listAll();
  return (
    tags: tags.map((Tag t) => t.name).toSet(),
    authors: authors.map((Author a) => a.name).toSet(),
  );
}

final librarySearchPageComicsProvider =
    FutureProvider.family<List<Comic>, String>((Ref ref, String keyword) async {
      final String trimmed = keyword.trim();
      if (trimmed.isEmpty) {
        return <Comic>[];
      }
      final _SearchVocabulary vocabulary = await _loadSearchVocabulary(ref);
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        trimmed,
        knownTagNames: vocabulary.tags,
        knownAuthorNames: vocabulary.authors,
      );
      return switch (query) {
        LibrarySearchKeywordQuery(:final keyword) =>
          ref.read(comicRepoProvider).searchByKeyword(keyword),
        LibrarySearchMetadataQuery(
          :final mustInclude,
          :final optionalOr,
          :final mustExclude,
        ) =>
          ref
              .read(comicRepoProvider)
              .searchByMetadataExpression(
                mustInclude: mustInclude,
                optionalOr: optionalOr,
                mustExclude: mustExclude,
              ),
      };
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
      final _SearchVocabulary vocabulary = await _loadSearchVocabulary(ref);
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        trimmed,
        knownTagNames: vocabulary.tags,
        knownAuthorNames: vocabulary.authors,
      );
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
    });
