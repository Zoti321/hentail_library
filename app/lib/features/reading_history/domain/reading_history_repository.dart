import 'package:hentai_library/features/reading_history/domain/reading_history.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';

abstract class ReadingHistoryRepository {
  Future<void> recordReading(ReadingHistory history);

  Future<ReadingHistory?> getByComicId(String comicId);

  /// 库 revision 变更通知；不携带全表数据。
  Stream<void> watchHistoryChanges();

  /// 封面进度条等轻量读侧：comicId → 1-based pageIndex。
  Future<Map<String, int>> listReadPageIndexes();

  Future<PagedResult<ReadingHistory>> fetchHistoryPage(
    PageRequest request, {
    String? keyword,
  });

  Future<void> deleteByComicId(String comicId);

  /// 批量删除阅读历史（如清空漫画库时）。
  Future<void> deleteByComicIds(Iterable<String> comicIds);

  Future<void> clearAllHistory();
}
