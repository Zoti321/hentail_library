import 'package:hentai_library/domain/entity/reading_history.dart';

abstract class ReadingHistoryRepository {
  Future<void> recordReading(ReadingHistory history);

  Future<ReadingHistory?> getByComicId(String comicId);

  Stream<List<ReadingHistory>> watchAllHistory();

  Future<void> clearExpiredHistory();
}
