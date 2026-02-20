import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/domain/entity/entities.dart' as entity;
import 'package:drift/drift.dart';

// 阅读历史 Row <-> Entity 映射
extension ReadingHistoryRowToEntity on ComicReadingHistoryRow {
  entity.ReadingHistory toEntity() {
    return entity.ReadingHistory(
      comicId: comicId,
      title: title,
      lastReadTime: lastReadTime,
      pageIndex: pageIndex,
    );
  }
}

extension ReadingHistoryEntityToCompanion on entity.ReadingHistory {
  ComicReadingHistoriesCompanion toCompanion() {
    return ComicReadingHistoriesCompanion.insert(
      comicId: comicId,
      title: title,
      lastReadTime: lastReadTime,
      pageIndex: Value.absentIfNull(pageIndex),
    );
  }
}

extension SeriesReadingHistoryRowToEntity on SeriesReadingHistoryRow {
  entity.SeriesReadingHistory toEntity() {
    return entity.SeriesReadingHistory(
      seriesName: seriesName,
      lastReadComicId: lastReadComicId,
      lastReadTime: lastReadTime,
      pageIndex: pageIndex,
    );
  }
}

extension SeriesReadingHistoryEntityToCompanion on entity.SeriesReadingHistory {
  SeriesReadingHistoriesCompanion toSeriesCompanion() {
    return SeriesReadingHistoriesCompanion.insert(
      seriesName: seriesName,
      lastReadComicId: lastReadComicId,
      lastReadTime: lastReadTime,
      pageIndex: Value.absentIfNull(pageIndex),
    );
  }
}
