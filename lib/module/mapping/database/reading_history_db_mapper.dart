import 'package:drift/drift.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/model/models.dart' as entity;

class ReadingHistoryDbMapper {
  const ReadingHistoryDbMapper();
}

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

