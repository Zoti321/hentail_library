import 'package:hentai_library/domain/entity/reading_history.dart';

abstract class ReadingHistoryRepository {
  Future<void> recordReading(ReadingHistory history);

  Future<ReadingHistory?> getByComicId(String comicId);

  Stream<List<ReadingHistory>> watchAllHistory();

  Future<void> deleteByComicId(String comicId);

  /// 批量删除阅读历史（如清空漫画库时）。
  Future<void> deleteByComicIds(Iterable<String> comicIds);

  Future<void> clearAllHistory();

  Future<void> clearExpiredHistory();
}
