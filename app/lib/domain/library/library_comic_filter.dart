import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/library_author_pick.dart';
import 'package:hentai_library/domain/models/value_objects/library_tag_pick.dart';

part 'library_comic_filter.freezed.dart';

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
    Set<String>? parodies,
    Set<String>? characters,
  }) = _LibraryComicFilter;

  LibraryComicFilter._();

  bool matches(Comic comic) {
    if (query != null && query!.trim().isNotEmpty) {
      final q = query!.toLowerCase();
      final inTitle = comic.title.toLowerCase().contains(q);
      final inAuthors = comic.authors.any(
        (a) => a.name.toLowerCase().contains(q),
      );
      final inParodies = comic.parodies.any(
        (p) => p.toLowerCase().contains(q),
      );
      final inCharacters = comic.characters.any(
        (c) => c.toLowerCase().contains(q),
      );
      if (!inTitle && !inAuthors && !inParodies && !inCharacters) return false;
    }
    if (!showR18 && comic.contentRating == ContentRating.r18) {
      return false;
    }
    if (resourceTypes != null && resourceTypes!.isNotEmpty) {
      if (!resourceTypes!.contains(comic.resourceType)) return false;
    }
    if (contentRatings != null && contentRatings!.isNotEmpty) {
      if (!contentRatings!.contains(comic.contentRating)) return false;
    }
    if (tagsAll != null && tagsAll!.isNotEmpty) {
      if (!tagsAll!.every((p) => p.matchesComic(comic))) return false;
    }
    if (tagsAny != null && tagsAny!.isNotEmpty) {
      if (!tagsAny!.any((p) => p.matchesComic(comic))) return false;
    }
    if (tagsExclude != null && tagsExclude!.isNotEmpty) {
      if (tagsExclude!.any((p) => p.matchesComic(comic))) return false;
    }
    if (authorsAll != null && authorsAll!.isNotEmpty) {
      if (!authorsAll!.every((p) => p.matchesComic(comic))) return false;
    }
    if (authorsAny != null && authorsAny!.isNotEmpty) {
      if (!authorsAny!.any((p) => p.matchesComic(comic))) return false;
    }
    if (authorsExclude != null && authorsExclude!.isNotEmpty) {
      if (authorsExclude!.any((p) => p.matchesComic(comic))) return false;
    }
    if (languages != null && languages!.isNotEmpty) {
      if (!_anyIgnoreCase(comic.languages, languages!)) return false;
    }
    if (parodies != null && parodies!.isNotEmpty) {
      if (!_anyIgnoreCase(comic.parodies, parodies!)) return false;
    }
    if (characters != null && characters!.isNotEmpty) {
      if (!_anyIgnoreCase(comic.characters, characters!)) return false;
    }
    return true;
  }
}

bool _anyIgnoreCase(Iterable<String> values, Set<String> selected) {
  final Set<String> wanted = selected
      .map((String s) => s.toLowerCase())
      .toSet();
  return values.any((String value) => wanted.contains(value.toLowerCase()));
}
