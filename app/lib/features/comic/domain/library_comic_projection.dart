import 'package:hentai_library/features/comic/domain/library_comic_filter.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/shared/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/shared/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_author_pick.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_tag_pick.dart';

/// 库页 Comic 列表投影：intent 与年龄限制 → [LibraryComicFilter]。
class LibraryComicProjection {
  const LibraryComicProjection();

  LibraryComicFilter buildListFilter({
    required LibraryAgeRestrictionFilter ageRestriction,
    required LibraryMediaTypeFilterSelection mediaTypeFilter,
    required LibraryMetadataFilterSelection tagFilter,
    required LibraryMetadataFilterSelection authorFilter,
    Set<String> languages = const <String>{},
    LibraryMetadataFilterSelection parodyFilter =
        const LibraryMetadataFilterSelection(),
    LibraryMetadataFilterSelection characterFilter =
        const LibraryMetadataFilterSelection(),
    bool needsMetadataOnly = false,
    String? keyword,
    String? libraryId,
  }) {
    final String? query = keyword?.trim().isEmpty ?? true
        ? null
        : keyword!.trim();
    final LibraryMetadataFilterSets tagSets = tagFilter.toFilterSets();
    final LibraryMetadataFilterSets authorSets = authorFilter.toFilterSets();
    final LibraryMetadataFilterSets parodySets = parodyFilter.toFilterSets();
    final LibraryMetadataFilterSets characterSets = characterFilter
        .toFilterSets();
    return LibraryComicFilter(
      showR18: ageRestriction.comicShowR18(),
      query: query,
      resourceTypes: mediaTypeFilter.comicResourceTypes(),
      contentRatings: ageRestriction.comicContentRatings(),
      displayTarget: LibraryDisplayTarget.comics,
      tagsAll: _mapTagNames(tagSets.all),
      tagsAny: _mapTagNames(tagSets.any),
      tagsExclude: _mapTagNames(tagSets.exclude),
      authorsAll: _mapAuthorIds(authorSets.all),
      authorsAny: _mapAuthorIds(authorSets.any),
      authorsExclude: _mapAuthorIds(authorSets.exclude),
      languages: languages.isEmpty ? null : languages,
      parodiesAll: _mapStringSet(parodySets.all),
      parodiesAny: _mapStringSet(parodySets.any),
      parodiesExclude: _mapStringSet(parodySets.exclude),
      charactersAll: _mapStringSet(characterSets.all),
      charactersAny: _mapStringSet(characterSets.any),
      charactersExclude: _mapStringSet(characterSets.exclude),
      needsMetadataOnly: needsMetadataOnly,
      libraryId: libraryId,
    );
  }

  Set<String>? _mapStringSet(Set<String> names) {
    if (names.isEmpty) {
      return null;
    }
    return names;
  }

  Set<LibraryTagPick>? _mapTagNames(Set<String> names) {
    if (names.isEmpty) {
      return null;
    }
    return names.map((String name) => LibraryTagPick(name: name)).toSet();
  }

  Set<LibraryAuthorPick>? _mapAuthorIds(Set<String> ids) {
    if (ids.isEmpty) {
      return null;
    }
    return ids
        .map((String raw) {
          final int? id = int.tryParse(raw);
          if (id == null) {
            return null;
          }
          return LibraryAuthorPick(id: id, name: raw);
        })
        .whereType<LibraryAuthorPick>()
        .toSet();
  }
}
