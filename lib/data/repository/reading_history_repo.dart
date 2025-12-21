import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/mappers.dart';
import 'package:hentai_library/domain/entity/entities.dart' as entity;
import 'package:hentai_library/domain/repository/reading_history_repo.dart';

class ReadingHistoryRepositoryImpl implements ReadingHistoryRepository {
  final ReadingHistoryDao _dao;

  ReadingHistoryRepositoryImpl(this._dao);

  @override
  Future<void> recordReading(entity.ReadingHistory history) async {
    try {
      final companion = history.toCompanion();
      await _dao.recordReading(companion);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_HISTORY_REPO] 记录阅读进度失败，comicId=${history.comicId}',
      );
      throw AppException('记录阅读进度失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<entity.ReadingHistory?> getByComicId(String comicId) async {
    final row = await _dao.getReadingHistoryByComicId(comicId);
    return row?.toEntity();
  }

  @override
  Stream<List<entity.ReadingHistory>> watchAllHistory() {
    return _dao.watchAllHistory().map(
      (event) => event.map((e) => e.toEntity()).toList(),
    );
  }

  @override
  Future<void> clearExpiredHistory() async {
    try {
      await _dao.clearExpiredHistory();
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_HISTORY_REPO] 清理过期阅读历史失败',
      );
      throw AppException('清理过期阅读历史失败', cause: e, stackTrace: st);
    }
  }
}
