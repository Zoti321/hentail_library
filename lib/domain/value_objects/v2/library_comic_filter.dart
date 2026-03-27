import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/data/services/comic/v2/resource_types.dart';
import 'package:hentai_library/domain/entity/v2/library_comic.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/value_objects/v2/library_tag_pick.dart';

part 'library_comic_filter.freezed.dart';

@freezed
abstract class LibraryComicFilter with _$LibraryComicFilter {
  factory LibraryComicFilter({
    String? query,
    @Default(false) bool showR18,
    Set<ResourceType>? resourceTypes,
    Set<ContentRating>? contentRatings,
    Set<LibraryTagPick>? tagsAll,
    Set<LibraryTagPick>? tagsAny,
    Set<LibraryTagPick>? tagsExclude,
  }) = _LibraryComicFilter;

  LibraryComicFilter._();

  bool matches(LibraryComic comic) {
    if (query != null && query!.trim().isNotEmpty) {
      final q = query!.toLowerCase();
      final inTitle = comic.title.toLowerCase().contains(q);
      final inAuthors = comic.authors.any((a) => a.toLowerCase().contains(q));
      if (!inTitle && !inAuthors) return false;
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

    return true;
  }
}
