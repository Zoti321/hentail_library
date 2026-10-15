import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/library_author_pick.dart';
import 'package:hentai_library/domain/models/value_objects/library_tag_pick.dart';

/// 库页 Comic 列表投影：intent 与年龄限制 → [LibraryComicFilter]。
class LibraryComicProjection {
  const LibraryComicProjection();

  LibraryComicFilter buildListFilter({
    required LibraryAgeRestrictionFilter ageRestriction,
    required LibraryMediaTypeFilterSelection mediaTypeFilter,
    required LibraryMetadataFilterSelection tagFilter,
    required LibraryMetadataFilterSelection authorFilter,
    Set<String> languages = const <String>{},
    Set<String> parodies = const <String>{},
    Set<String> characters = const <String>{},
    String? keyword,
  }) {
    final String? query = keyword?.trim().isEmpty ?? true
        ? null
        : keyword!.trim();
    final LibraryMetadataFilterSets tagSets = tagFilter.toFilterSets();
    final LibraryMetadataFilterSets authorSets = authorFilter.toFilterSets();
    return LibraryComicFilter(
      showR18: ageRestriction.comicShowR18(),
      query: query,
      resourceTypes: mediaTypeFilter.comicResourceTypes(),
      contentRatings: ageRestriction.comicContentRatings(),
      displayTarget: LibraryDisplayTarget.comics,
      tagsAll: _mapTagNames(tagSets.all),
      tagsAny: _mapTagNames(tagSets.any),
      tagsExclude: _mapTagNames(tagSets.exclude),
      authorsAll: _mapAuthorNames(authorSets.all),
      authorsAny: _mapAuthorNames(authorSets.any),
      authorsExclude: _mapAuthorNames(authorSets.exclude),
      languages: languages.isEmpty ? null : languages,
      parodies: parodies.isEmpty ? null : parodies,
      characters: characters.isEmpty ? null : characters,
    );
  }

  Set<LibraryTagPick>? _mapTagNames(Set<String> names) {
    if (names.isEmpty) {
      return null;
    }
    return names.map((String name) => LibraryTagPick(name: name)).toSet();
  }

  Set<LibraryAuthorPick>? _mapAuthorNames(Set<String> names) {
    if (names.isEmpty) {
      return null;
    }
    return names.map((String name) => LibraryAuthorPick(name: name)).toSet();
  }
}
