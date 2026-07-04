import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';

/// 库页 Comic 列表投影：intent 与年龄限制 → [LibraryComicFilter]。
class LibraryComicProjection {
  const LibraryComicProjection();

  LibraryComicFilter buildListFilter({
    required LibraryAgeRestrictionFilter ageRestriction,
    String? keyword,
  }) {
    final String? query = keyword?.trim().isEmpty ?? true
        ? null
        : keyword!.trim();
    return LibraryComicFilter(
      showR18: ageRestriction.comicShowR18(),
      query: query,
      contentRatings: ageRestriction.comicContentRatings(),
      displayTarget: LibraryDisplayTarget.comics,
    );
  }
}
