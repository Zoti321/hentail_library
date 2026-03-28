import 'package:hentai_library/domain/entity/reading_session.dart';

abstract class ReadingSessionRepository {
  Future<void> recordSession(ReadingSession session);

  Future<List<ReadingSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  );

  /// 删除一年前的阅读会话，仅保留最近一年数据。
  Future<void> clearExpiredSessions();

  /// 按漫画 id 批量删除阅读会话（如清空漫画库时）。
  Future<void> deleteSessionsByComicIds(Iterable<String> comicIds);
}
