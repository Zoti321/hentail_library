import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/core/logging/log_manager.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/mappers.dart';
import 'package:hentai_library/domain/entity/entities.dart' as entity;
import 'package:hentai_library/domain/repository/reading_session_repo.dart';

class ReadingSessionRepositoryImpl implements ReadingSessionRepository {
  final ReadingSessionDao _dao;

  ReadingSessionRepositoryImpl(this._dao);

  @override
  Future<void> recordSession(entity.ReadingSession session) async {
    try {
      final companion = session.toCompanion();
      await _dao.insertSession(companion);
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_SESSION_REPO] 记录阅读会话失败，comicId=${session.comicId}',
      );
      throw AppException('记录阅读会话失败', cause: e, stackTrace: st);
    }
  }

  @override
  Future<List<entity.ReadingSession>> getSessionsInRange(
    DateTime start,
    DateTime end,
  ) async {
    final rows = await _dao.getSessionsByDateRange(start, end);
    return rows.map((row) => row.toEntity()).toList();
  }

  @override
  Future<void> clearExpiredSessions() async {
    try {
      await _dao.clearExpiredSessions();
    } catch (e, st) {
      LogManager.instance.handle(
        e,
        st,
        '[READING_SESSION_REPO] 清理过期阅读会话失败',
      );
      throw AppException('清理过期阅读会话失败', cause: e, stackTrace: st);
    }
  }
}
