import 'package:hentai_library/features/series/public/library_series_browse_rules.dart';

import 'package:hentai_library/features/series/public/library_age_restriction_series.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';

/// 库页系列列表装配：intent 与年龄限制 → [LibrarySeriesFilter]。
class SeriesCatalogQueryAssembly {
  const SeriesCatalogQueryAssembly();

  LibrarySeriesFilter buildListFilter({
    required LibraryAgeRestrictionFilter ageRestriction,
    LibrarySerializationStatusFilter serializationStatusFilter =
        LibrarySerializationStatusFilter.unrestricted,
    bool preferLibraryRootSeries = true,
    String? keyword,
    String? libraryId,
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
      serializationStatus: serializationStatusFilter
          .seriesSerializationStatus(),
      preferLibraryRootSeries: preferLibraryRootSeries,
      libraryId: libraryId,
    );
  }
}
