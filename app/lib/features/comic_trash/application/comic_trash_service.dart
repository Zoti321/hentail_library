import 'package:hentai_library/features/comic_trash/domain/comic_trash_target_ids_specification.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/shared/domain/ports/comic_trash_reader_session_port.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_repository.dart';

/// Comic trash / restore / purge 与「已删除」列表查询（ADR-0023）。
///
/// 写入成功后发布 `ComicsTrashed` / `ComicsRestored`（ADR-0039）。
class ComicTrashService {
  const ComicTrashService({
    required this._comicRepository,
    required this._readerSessionPort,
    required this._events,
  });

  final ComicTrashRepository _comicRepository;
  final ComicTrashNativeReaderPort _readerSessionPort;
  final DomainEventPublisher _events;

  Future<void> trashComics(Iterable<String> comicIds) async {
    final List<String> ids = ComicTrashTargetIdsSpecification.normalize(
      comicIds,
    );
    if (ids.isEmpty) {
      return;
    }
    await _closeSessions(ids);
    await _comicRepository.trashByIds(ids);
    _events.publish(ComicsTrashed(ids));
  }

  Future<void> restoreComics(Iterable<String> comicIds) async {
    final List<String> ids = ComicTrashTargetIdsSpecification.normalize(
      comicIds,
    );
    if (ids.isEmpty) {
      return;
    }
    await _comicRepository.restoreByIds(ids);
    _events.publish(ComicsRestored(ids));
  }

  Future<int> restoreAll() async {
    final List<String> ids = await listTrashedIds();
    if (ids.isEmpty) {
      return 0;
    }
    await _comicRepository.restoreByIds(ids);
    _events.publish(ComicsRestored(ids));
    return ids.length;
  }

  Future<ComicPurgeResult> purgeComics(Iterable<String> comicIds) async {
    final List<String> ids = ComicTrashTargetIdsSpecification.normalize(
      comicIds,
    );
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
