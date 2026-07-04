import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;
import 'package:hentai_library/src/rust/api/series.dart' as rust_series;

Series mapRustSeries(rust_series.SeriesDto dto) {
  return Series(
    name: dto.name,
    items: dto.items.map(mapRustSeriesItem).toList(),
  );
}

SeriesItem mapRustSeriesItem(rust_series.SeriesItemDto dto) {
  return SeriesItem(comicId: dto.comicId, order: dto.sortOrder);
}

rust_series.SeriesFilterDto mapLibrarySeriesFilter(LibrarySeriesFilter filter) {
  return rust_series.SeriesFilterDto(
    showR18: filter.showR18,
    r18Only: filter.r18Only,
    query: filter.query,
    requireItems: filter.requireItems,
  );
}

rust_series.SeriesSortOptionDto mapSeriesSortOption(
  LibraryComicSortOption sortOption,
) {
  return rust_series.SeriesSortOptionDto(descending: sortOption.descending);
}

PagedResult<Series> mapPagedSeriesResult(
  rust_series.PagedSeriesResultDto page,
) {
  return PagedResult<Series>(
    items: page.items.map(mapRustSeries).toList(),
    totalCount: page.totalCount.toInt(),
    page: page.page,
    pageSize: page.pageSize,
  );
}

rust.PageRequestDto mapSeriesPageRequest(PageRequest request) {
  return rust.PageRequestDto(page: request.page, pageSize: request.pageSize);
}
