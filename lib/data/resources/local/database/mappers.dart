import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/domain/entity/entities.dart' as entity;
import 'package:drift/drift.dart';

// 阅读历史 Row <-> Entity 映射
extension ReadingHistoryRowToEntity on ReadingHistory {
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
  ReadingHistoriesCompanion toCompanion() {
    return ReadingHistoriesCompanion.insert(
      comicId: comicId,
      title: title,
      lastReadTime: lastReadTime,
      pageIndex: Value.absentIfNull(pageIndex),
    );
  }
}

// 阅读会话 Row <-> Entity 映射（Drift ReadingSession 来自 database.dart）
extension ReadingSessionRowToEntity on ReadingSession {
  entity.ReadingSession toEntity() {
    return entity.ReadingSession(
      comicId: comicId,
      date: date,
      durationSeconds: durationSeconds,
    );
  }
}

extension ReadingSessionEntityToCompanion on entity.ReadingSession {
  ReadingSessionsCompanion toCompanion() {
    return ReadingSessionsCompanion.insert(
      comicId: comicId,
      date: date,
      durationSeconds: durationSeconds,
    );
  }
}
