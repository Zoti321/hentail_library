import 'package:hentai_library/features/reading_history/domain/reading_history.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';

class RecordReadingProgressUseCase {
  const RecordReadingProgressUseCase(this._repo);
  final ReadingHistoryRepository _repo;
  Future<void> call({
    required String comicId,
    required String title,
    required DateTime lastReadTime,
    required int pageIndex,
  }) {
    final ReadingHistory snapshot = ReadingHistory.recordSessionProgress(
      comicId: comicId,
      title: title,
      lastReadTime: lastReadTime,
      pageIndex: pageIndex,
    );
    return _repo.recordReading(snapshot);
  }
}
