import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';

/// 从 Library 移除 Comic 并清理关联阅读副作用。
class ComicDeletionService {
  const ComicDeletionService({
    required ComicRepository comicRepository,
    required ReaderSessionPort readerSessionPort,
  }) : _comicRepository = comicRepository,
       _readerSessionPort = readerSessionPort;

  final ComicRepository _comicRepository;
  final ReaderSessionPort _readerSessionPort;

  Future<void> deleteComics(Iterable<String> comicIds) async {
    final List<String> ids = comicIds.toList();
    if (ids.isEmpty) {
      return;
    }
    for (final String comicId in ids) {
      await _readerSessionPort.closeComic(comicId);
    }
    await _comicRepository.deleteByIds(ids);
  }
}
