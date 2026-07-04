import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';

/// 库页系列列表投影：intent 与年龄限制 → [LibrarySeriesFilter]。
class LibrarySeriesFilter {
  const LibrarySeriesFilter({
    required this.showR18,
    required this.r18Only,
    this.query,
    this.requireItems = true,
  });

  final bool showR18;
  final bool r18Only;
  final String? query;
  final bool requireItems;
}

class LibrarySeriesProjection {
  const LibrarySeriesProjection();

  LibrarySeriesFilter buildListFilter({
    required LibraryAgeRestrictionFilter ageRestriction,
    String? keyword,
  }) {
    final String? query = keyword?.trim().isEmpty ?? true
        ? null
        : keyword!.trim();
    final ({bool showR18, bool r18Only}) flags = ageRestriction
        .seriesFilterFlags();
    return LibrarySeriesFilter(
      showR18: flags.showR18,
      r18Only: flags.r18Only,
      query: query,
      requireItems: true,
    );
  }
}
