import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/shared/domain/ports/reading_history_progress_port.dart';

class _ReadingHistoryProgressAdapter implements ReadingHistoryProgressPort {
  _ReadingHistoryProgressAdapter(this._repo);

  final ReadingHistoryRepository _repo;

  @override
  Stream<Map<String, int>> watchReadPageIndexes() async* {
    yield await _repo.listReadPageIndexes();
    await for (final _ in _repo.watchHistoryChanges()) {
      yield await _repo.listReadPageIndexes();
    }
  }
}

ReadingHistoryProgressPort createReadingHistoryProgressPort(Ref ref) =>
    _ReadingHistoryProgressAdapter(ref.read(readingHistoryRepoProvider));
