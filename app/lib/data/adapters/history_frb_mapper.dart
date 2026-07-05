import 'package:hentai_library/domain/models/models.dart' as entity;
import 'package:hentai_library/domain/models/entity/series_reading_history.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/history.dart' as rust;

entity.ReadingHistory mapReadingHistoryDto(rust.ReadingHistoryDto dto) {
  return entity.ReadingHistory(
    comicId: dto.comicId,
    title: dto.title,
    lastReadTime: DateTime.fromMillisecondsSinceEpoch(
      dto.lastReadTimeMs.toInt(),
    ),
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

SeriesReadingHistory mapSeriesReadingHistoryDto(
  rust.SeriesReadingHistoryDto dto,
) {
  return SeriesReadingHistory(
    seriesId: dto.seriesId,
    lastReadComicId: dto.lastReadComicId,
    lastReadTime: DateTime.fromMillisecondsSinceEpoch(
      dto.lastReadTimeMs.toInt(),
    ),
    pageIndex: dto.pageIndex,
  );
}

rust.SeriesReadingHistoryDto toSeriesReadingHistoryDto(
  SeriesReadingHistory history,
) {
  return rust.SeriesReadingHistoryDto(
    seriesId: history.seriesId,
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
