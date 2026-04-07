import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/mappers.dart';
import 'package:hentai_library/domain/entity/entities.dart' as entity;
import 'package:hentai_library/domain/repository/reading_history_repo.dart';

class ReadingHistoryRepositoryImpl implements ReadingHistoryRepository {
  ReadingHistoryRepositoryImpl(this._dao, this._seriesDao);

  final ReadingHistoryDao _dao;
  final SeriesReadingHistoryDao _seriesDao;

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
  Future<void> recordSeriesReading(entity.SeriesReadingHistory history) async {
    try {
      final companion = history.toSeriesCompanion();
      await _seriesDao.recordSeriesReading(companion);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_HISTORY_REPO] 记录系列阅读进度失败，seriesName=${history.seriesName}',
      );
      throw AppException('记录系列阅读进度失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<entity.SeriesReadingHistory?> getSeriesReadingBySeriesName(
    String seriesName,
  ) async {
    final row = await _seriesDao.getBySeriesName(seriesName);
    return row?.toEntity();
  }

  @override
  Stream<List<entity.SeriesReadingHistory>> watchAllSeriesReading() {
    return _seriesDao.watchAllSeriesReading().map(
      (event) => event.map((e) => e.toEntity()).toList(),
    );
  }

  @override
  Future<void> deleteByComicId(String comicId) async {
    try {
      await _dao.deleteByComicId(comicId);
      await _seriesDao.deleteByLastReadComicIds(<String>[comicId]);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_HISTORY_REPO] 删除阅读历史失败，comicId=$comicId',
      );
      throw AppException('删除阅读历史失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteByComicIds(Iterable<String> comicIds) async {
    try {
      await _dao.deleteByComicIds(comicIds);
      await _seriesDao.deleteByLastReadComicIds(comicIds);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_HISTORY_REPO] 批量删除阅读历史失败',
      );
      throw AppException('批量删除阅读历史失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> deleteSeriesReadingByLastReadComicIds(
    Iterable<String> comicIds,
  ) async {
    try {
      await _seriesDao.deleteByLastReadComicIds(comicIds);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_HISTORY_REPO] 按漫画删除系列阅读历史失败',
      );
      throw AppException('删除系列阅读历史失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> clearAllHistory() async {
    try {
      await _dao.clearAllHistory();
      await _seriesDao.clearAllSeriesReading();
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_HISTORY_REPO] 清空阅读历史失败',
      );
      throw AppException('清空阅读历史失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> clearExpiredHistory() async {
    try {
      await _dao.clearExpiredHistory();
      await _seriesDao.clearExpiredSeriesReading();
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
