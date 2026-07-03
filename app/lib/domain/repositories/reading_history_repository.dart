import 'package:hentai_library/domain/models/models.dart' as entity;
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';

abstract class ReadingHistoryRepository {
  Future<void> recordReading(entity.ReadingHistory history);

  Future<entity.ReadingHistory?> getByComicId(String comicId);

  Stream<List<entity.ReadingHistory>> watchAllHistory();

  Future<PagedResult<entity.ReadingHistory>> fetchHistoryPage(
    PageRequest request,
  );

  Future<void> deleteByComicId(String comicId);

  /// 批量删除阅读历史（如清空漫画库时）。
  Future<void> deleteByComicIds(Iterable<String> comicIds);

  Future<void> clearAllHistory();

  Future<void> clearExpiredHistory();
}
