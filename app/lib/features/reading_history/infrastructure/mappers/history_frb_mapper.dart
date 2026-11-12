import 'package:hentai_library/features/reading_history/domain/reading_history.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/history.dart' as rust;

ReadingHistory mapReadingHistoryDto(rust.ReadingHistoryDto dto) {
  return ReadingHistory(
    comicId: dto.comicId,
    title: dto.title,
    lastReadTime: DateTime.fromMillisecondsSinceEpoch(
      dto.lastReadTimeMs.toInt(),
    ),
    pageIndex: dto.pageIndex,
    pageCount: dto.pageCount,
  );
}

rust.ReadingHistoryDto toReadingHistoryDto(ReadingHistory history) {
  return rust.ReadingHistoryDto(
    comicId: history.comicId,
    title: history.title,
    lastReadTimeMs: history.lastReadTime.millisecondsSinceEpoch,
    pageIndex: history.pageIndex,
  );
}

PagedResult<ReadingHistory> mapPagedReadingHistory(
  rust.PagedReadingHistoryDto dto,
) {
  return PagedResult<ReadingHistory>(
    items: dto.items.map(mapReadingHistoryDto).toList(growable: false),
    totalCount: dto.totalCount.toInt(),
    page: dto.page,
    pageSize: dto.pageSize,
  );
}
