import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/value_objects/comic_language.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_series_providers.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_query_parser.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/current_library_notifier.dart';

typedef _SearchVocabulary = ({
  Set<String> tags,
  Set<String> authors,
  Set<String> parodies,
  Set<String> characters,
  Set<String> languages,
});

Future<_SearchVocabulary> _loadSearchVocabulary(Ref ref) async {
  final String? libraryId = ref
      .watch(currentLibraryProvider)
      .asData
      ?.value
      .currentId;
  final List<Tag> tags = await ref.read(tagRepoProvider).listAll();
  final List<Author> authors = await ref.read(authorRepoProvider).listAll();
  final List<String> parodies =
      await ref.read(parodyRepoProvider).listDistinct(libraryId: libraryId);
  final List<String> characters =
      await ref.read(characterRepoProvider).listDistinct(libraryId: libraryId);
  return (
    tags: tags.map((Tag t) => t.name).toSet(),
    authors: authors.map((Author a) => a.name).toSet(),
    parodies: parodies.toSet(),
    characters: characters.toSet(),
    languages: ComicLanguageNames.closedSet.toSet(),
  );
}

LibrarySearchQuery _parse(String trimmed, _SearchVocabulary vocabulary) {
  return parseLibrarySearchQuery(
    trimmed,
    knownTagNames: vocabulary.tags,
    knownAuthorNames: vocabulary.authors,
    knownParodyNames: vocabulary.parodies,
    knownCharacterNames: vocabulary.characters,
    knownLanguageNames: vocabulary.languages,
  );
}

final librarySearchPageComicsProvider =
    FutureProvider.family<List<Comic>, String>((Ref ref, String keyword) async {
      final String trimmed = keyword.trim();
      if (trimmed.isEmpty) {
        return <Comic>[];
      }
      final _SearchVocabulary vocabulary = await _loadSearchVocabulary(ref);
      final LibrarySearchQuery query = _parse(trimmed, vocabulary);
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
    });
