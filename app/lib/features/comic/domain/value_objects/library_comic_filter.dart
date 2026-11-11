import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_author_pick.dart';
import 'package:hentai_library/shared/domain/models/value_objects/library_tag_pick.dart';

part 'library_comic_filter.freezed.dart';

/// Comic catalog filter **intent** assembled in Dart; predicates live in Rust core.
@freezed
abstract class LibraryComicFilter with _$LibraryComicFilter {
  factory LibraryComicFilter({
    String? query,
    @Default(true) bool showR18,
    @Default(LibraryDisplayTarget.comics) LibraryDisplayTarget displayTarget,
    Set<ResourceType>? resourceTypes,
    Set<ContentRating>? contentRatings,
    Set<LibraryTagPick>? tagsAll,
    Set<LibraryTagPick>? tagsAny,
    Set<LibraryTagPick>? tagsExclude,
    Set<LibraryAuthorPick>? authorsAll,
    Set<LibraryAuthorPick>? authorsAny,
    Set<LibraryAuthorPick>? authorsExclude,
    Set<String>? languages,
    Set<String>? parodiesAll,
    Set<String>? parodiesAny,
    Set<String>? parodiesExclude,
    Set<String>? charactersAll,
    Set<String>? charactersAny,
    Set<String>? charactersExclude,
    @Default(false) bool needsMetadataOnly,
    String? libraryId,
  }) = _LibraryComicFilter;
}
