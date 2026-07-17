import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/models/value_objects/series_comics_metadata.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;
import 'package:hentai_library/src/rust/api/series.dart' as rust_series;

/// FRB `SeriesDto` → 领域 `Series`（唯一 Dart 侧映射入口）。
Series mapRustSeries(rust_series.SeriesDto dto) {
  return Series(
    id: dto.seriesId,
    name: dto.name,
    folderPath: dto.folderPath,
    serializationStatus: SerializationStatus.fromRust(dto.serializationStatus),
    totalCount: dto.totalCount?.toInt(),
    items: dto.items.map(mapRustSeriesItem).toList(),
  );
}

SeriesItem mapRustSeriesItem(rust_series.SeriesItemDto dto) {
  return SeriesItem(comicId: dto.comicId, order: dto.sortOrder);
}

SeriesComicsMetadata mapRustSeriesComicsMetadata(
  rust_series.SeriesComicsMetadataDto dto,
) {
  return SeriesComicsMetadata(
    authors: dto.authors,
    tags: dto.tags,
    hasR18: dto.hasR18,
  );
}

rust_series.SeriesFilterDto mapLibrarySeriesFilter(LibrarySeriesFilter filter) {
  return rust_series.SeriesFilterDto(
    showR18: filter.showR18,
    r18Only: filter.r18Only,
    query: filter.query,
    requireItems: filter.requireItems,
  );
}

rust_series.SeriesSortOptionDto mapSeriesSortOption({
  required LibrarySeriesSortOption sortOption,
}) {
  return rust_series.SeriesSortOptionDto(
    field: switch (sortOption.field) {
      LibrarySeriesSortField.name => rust_series.SeriesSortFieldDto.name,
      LibrarySeriesSortField.comicCount =>
        rust_series.SeriesSortFieldDto.comicCount,
      LibrarySeriesSortField.random => rust_series.SeriesSortFieldDto.random,
    },
    descending: sortOption.descending,
  );
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

rust_series.UpdateSeriesUserMetaDto mapUpdateSeriesUserMeta({
  String? name,
  SerializationStatus? serializationStatus,
  int? totalCount,
  bool clearTotalCount = false,
}) {
  return rust_series.UpdateSeriesUserMetaDto(
    name: name,
    serializationStatus: serializationStatus?.toRust(),
    totalCount: totalCount,
    clearTotalCount: clearTotalCount,
  );
}
