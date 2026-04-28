import 'package:drift/drift.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/model/models.dart' as entity;

class SeriesReadingHistoryDbMapper {
  const SeriesReadingHistoryDbMapper();
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

