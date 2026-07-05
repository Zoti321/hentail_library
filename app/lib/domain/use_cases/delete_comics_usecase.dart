import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';

/// 从 Library 移除 Comic 并清理全部关联副作用。
class DeleteComicsUseCase {
  DeleteComicsUseCase({
    required ComicRepository comicRepository,
    required ReadingHistoryRepository readingHistoryRepository,
    required ReaderSessionPort readerSessionPort,
  }) : _comicRepository = comicRepository,
       _readingHistoryRepository = readingHistoryRepository,
       _readerSessionPort = readerSessionPort;

  final ComicRepository _comicRepository;
  final ReadingHistoryRepository _readingHistoryRepository;
  final ReaderSessionPort _readerSessionPort;

  Future<void> call(Iterable<String> comicIds) async {
    final List<String> ids = comicIds.toList();
    if (ids.isEmpty) {
      return;
    }
    await _readingHistoryRepository.deleteByComicIds(ids);
    await _comicRepository.deleteByIds(ids);
    await _readerSessionPort.clear();
  }
}
