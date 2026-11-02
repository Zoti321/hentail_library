import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_command_port.dart';

class _ReadingHistoryCommandAdapter implements ReadingHistoryCommandPort {
  _ReadingHistoryCommandAdapter(this._repo);

  final ReadingHistoryRepository _repo;

  @override
  Future<void> recordReading({
    required String comicId,
    required String title,
    required DateTime lastReadTime,
    required int pageIndex,
  }) {
    return _repo.recordReading(
      ReadingHistory(
        comicId: comicId,
        title: title,
        lastReadTime: lastReadTime,
        pageIndex: pageIndex,
      ),
    );
  }

  @override
  Future<int?> readResumePageIndex(String comicId) async {
    return (await _repo.getByComicId(comicId))?.pageIndex;
  }
}

ReadingHistoryCommandPort createReadingHistoryCommandPort(Ref ref) =>
    _ReadingHistoryCommandAdapter(ref.read(readingHistoryRepoProvider));
