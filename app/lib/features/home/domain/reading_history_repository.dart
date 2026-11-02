import 'package:hentai_library/features/home/domain/reading_history.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';

abstract class ReadingHistoryRepository {
  Future<void> recordReading(ReadingHistory history);

  Future<ReadingHistory?> getByComicId(String comicId);

  Stream<List<ReadingHistory>> watchAllHistory();

  Future<PagedResult<ReadingHistory>> fetchHistoryPage(
    PageRequest request, {
    String? keyword,
  });

  Future<void> deleteByComicId(String comicId);

  /// 批量删除阅读历史（如清空漫画库时）。
  Future<void> deleteByComicIds(Iterable<String> comicIds);

  Future<void> clearAllHistory();

  Future<void> clearExpiredHistory();
}
