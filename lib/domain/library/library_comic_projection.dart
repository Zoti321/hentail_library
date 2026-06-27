import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';

/// 库页 Comic 列表投影：intent、Healthy mode 与系列可见性 → [LibraryComicFilter]。
class LibraryComicProjection {
  const LibraryComicProjection();

  bool showR18({required bool isHealthyMode}) => !isHealthyMode;

  Set<String> collectComicIdsInAnySeries(Iterable<Series> seriesList) {
    final Set<String> comicIds = <String>{};
    for (final Series series in seriesList) {
      for (final SeriesItem item in series.items) {
        comicIds.add(item.comicId);
      }
    }
    return comicIds;
  }

  LibraryComicFilter buildListFilter({
    required LibraryDisplayTarget displayTarget,
    required bool isHealthyMode,
    required bool hideComicsInSeries,
    required Set<String> comicIdsInAnySeries,
    String? keyword,
  }) {
    final String? query = keyword?.trim().isEmpty ?? true ? null : keyword!.trim();
    return LibraryComicFilter(
      showR18: showR18(isHealthyMode: isHealthyMode),
      query: query,
      displayTarget: displayTarget,
      comicIdsExcludedBySeriesMembership: hideComicsInSeries
          ? comicIdsInAnySeries
          : null,
    );
  }
}
