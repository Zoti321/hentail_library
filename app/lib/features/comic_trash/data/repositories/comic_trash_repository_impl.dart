import 'package:hentai_library/features/comic_trash/data/adapters/comic_trash_frb_adapter.dart';
import 'package:hentai_library/features/comic_trash/data/mappers/comic_trash_frb_mapper.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_repository.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';

/// Comic trash / restore / purge 与「已删除」列表（FRB owner：comic_trash API）。
class ComicTrashRepositoryImpl implements ComicTrashRepository {
  const ComicTrashRepositoryImpl({ComicTrashFrbAdapter? adapter})
    : _adapter = adapter ?? const ComicTrashFrbAdapter();

  final ComicTrashFrbAdapter _adapter;

  @override
  Future<void> trashByIds(List<String> comicIds) async {
    if (comicIds.isEmpty) {
      return;
    }
    await _adapter.trashByIds(comicIds);
  }

  @override
  Future<void> restoreByIds(List<String> comicIds) async {
    if (comicIds.isEmpty) {
      return;
    }
    await _adapter.restoreByIds(comicIds);
  }

  @override
  Future<ComicPurgeResult> purgeByIds(List<String> comicIds) async {
    if (comicIds.isEmpty) {
      return (succeeded: 0, failed: 0, errorSamples: const <String>[]);
    }
    return mapComicPurgeResult(await _adapter.purgeByIds(comicIds));
  }

  @override
  Future<PagedResult<TrashedComic>> fetchTrashedPage(
    PageRequest request,
  ) async {
    final page = await _adapter.fetchTrashedPage(
      mapTrashPageRequest(page: request.page, pageSize: request.pageSize),
    );
    return mapTrashedComicsPage(page);
  }

  @override
  Future<TrashedComicCounts> countTrashed() async {
    return mapTrashedComicCounts(await _adapter.countTrashed());
  }

  @override
  Future<List<String>> listTrashedIds() => _adapter.listTrashedIds();
}
