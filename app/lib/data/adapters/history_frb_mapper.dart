import 'package:hentai_library/domain/models/models.dart' as entity;
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/history.dart' as rust;

entity.ReadingHistory mapReadingHistoryDto(rust.ReadingHistoryDto dto) {
  return entity.ReadingHistory(
    comicId: dto.comicId,
    title: dto.title,
    lastReadTime: DateTime.fromMillisecondsSinceEpoch(dto.lastReadTimeMs.toInt()),
    pageIndex: dto.pageIndex,
  );
}

entity.SeriesReadingHistory mapSeriesReadingHistoryDto(
  rust.SeriesReadingHistoryDto dto,
) {
  return entity.SeriesReadingHistory(
    seriesName: dto.seriesName,
    lastReadComicId: dto.lastReadComicId,
    lastReadTime: DateTime.fromMillisecondsSinceEpoch(dto.lastReadTimeMs.toInt()),
    pageIndex: dto.pageIndex,
  );
}

rust.ReadingHistoryDto toReadingHistoryDto(entity.ReadingHistory history) {
  return rust.ReadingHistoryDto(
    comicId: history.comicId,
    title: history.title,
    lastReadTimeMs: history.lastReadTime.millisecondsSinceEpoch,
    pageIndex: history.pageIndex,
  );
}

rust.SeriesReadingHistoryDto toSeriesReadingHistoryDto(
  entity.SeriesReadingHistory history,
) {
  return rust.SeriesReadingHistoryDto(
    seriesName: history.seriesName,
    lastReadComicId: history.lastReadComicId,
    lastReadTimeMs: history.lastReadTime.millisecondsSinceEpoch,
    pageIndex: history.pageIndex,
  );
}

PagedResult<entity.ReadingHistory> mapPagedReadingHistory(
  rust.PagedReadingHistoryDto dto,
  int page,
  int pageSize,
) {
  return PagedResult<entity.ReadingHistory>(
    items: dto.items.map(mapReadingHistoryDto).toList(growable: false),
    totalCount: dto.totalCount.toInt(),
    page: page,
    pageSize: pageSize,
  );
}

PagedResult<entity.SeriesReadingHistory> mapPagedSeriesReadingHistory(
  rust.PagedSeriesReadingHistoryDto dto,
  int page,
  int pageSize,
) {
  return PagedResult<entity.SeriesReadingHistory>(
    items: dto.items.map(mapSeriesReadingHistoryDto).toList(growable: false),
    totalCount: dto.totalCount.toInt(),
    page: page,
    pageSize: pageSize,
  );
}
