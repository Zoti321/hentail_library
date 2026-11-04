import 'package:hentai_library/features/comic_trash/domain/comic_trash_target_ids.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_reader_session_port.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_repository.dart';

/// Comic trash / restore / purge 与「已删除」列表查询（ADR-0023）。
class ComicTrashService {
  const ComicTrashService({
    required this._comicRepository,
    required this._readerSessionPort,
  });

  final ComicTrashRepository _comicRepository;
  final ComicTrashReaderSessionPort _readerSessionPort;

  Future<void> trashComics(Iterable<String> comicIds) async {
    final List<String> ids = normalizeComicTrashTargetIds(comicIds);
    if (ids.isEmpty) {
      return;
    }
    await _closeSessions(ids);
    await _comicRepository.trashByIds(ids);
  }

  Future<void> restoreComics(Iterable<String> comicIds) async {
    final List<String> ids = normalizeComicTrashTargetIds(comicIds);
    if (ids.isEmpty) {
      return;
    }
    await _comicRepository.restoreByIds(ids);
  }

  Future<int> restoreAll() async {
    final List<String> ids = await listTrashedIds();
    if (ids.isEmpty) {
      return 0;
    }
    await _comicRepository.restoreByIds(ids);
    return ids.length;
  }

  Future<ComicPurgeResult> purgeComics(Iterable<String> comicIds) async {
    final List<String> ids = normalizeComicTrashTargetIds(comicIds);
    if (ids.isEmpty) {
      return (succeeded: 0, failed: 0, errorSamples: const <String>[]);
    }
    await _closeSessions(ids);
    return _comicRepository.purgeByIds(ids);
  }

  Future<List<String>> listTrashedIds() => _comicRepository.listTrashedIds();

  Future<PagedResult<TrashedComic>> fetchTrashedPage(PageRequest request) =>
      _comicRepository.fetchTrashedPage(request);

  Future<TrashedComicCounts> countTrashed() => _comicRepository.countTrashed();

  Future<void> _closeSessions(List<String> ids) async {
    for (final String comicId in ids) {
      await _readerSessionPort.closeComic(comicId);
    }
  }
}
