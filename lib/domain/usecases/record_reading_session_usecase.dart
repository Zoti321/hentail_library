import 'package:hentai_library/domain/entity/reading_session.dart';
import 'package:hentai_library/domain/repository/reading_session_repo.dart';

/// 用例：记录单次阅读会话（退出阅读页时调用，写入当日阅读时长）。
class RecordReadingSessionUseCase {
  final ReadingSessionRepository _repository;

  RecordReadingSessionUseCase(this._repository);

  Future<void> call(ReadingSession session) async {
    await _repository.recordSession(session);
  }
}
