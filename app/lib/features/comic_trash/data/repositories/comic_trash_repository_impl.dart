import 'package:hentai_library/features/comic_trash/data/mappers/comic_trash_frb_mapper.dart';
import 'package:hentai_library/features/comic_trash/domain/comic_trash_repository.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/shared/data/frb/frb_call_guard.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/comic_trash.dart' as rust;

/// Comic trash / restore / purge 与「已删除」列表（FRB owner：comic_trash API）。
class ComicTrashRepositoryImpl implements ComicTrashRepository {
  const ComicTrashRepositoryImpl();

  @override
  Future<void> trashByIds(List<String> comicIds) async {
    if (comicIds.isEmpty) {
      return;
    }
    await guardFrb(
      () => rust.trashComicsFrb(comicIds: comicIds),
      fallbackMessage: '移入已删除失败',
    );
  }

  @override
  Future<void> restoreByIds(List<String> comicIds) async {
    if (comicIds.isEmpty) {
      return;
    }
    await guardFrb(
      () => rust.restoreComicsFrb(comicIds: comicIds),
      fallbackMessage: '恢复漫画失败',
    );
  }

  @override
  Future<ComicPurgeResult> purgeByIds(List<String> comicIds) async {
    if (comicIds.isEmpty) {
      return (succeeded: 0, failed: 0, errorSamples: const <String>[]);
    }
    final rust.ComicPurgeResultFrbDto result = await guardFrb(
      () => rust.purgeComicsFrb(comicIds: comicIds),
      fallbackMessage: '永久删除漫画失败',
    );
    return mapComicPurgeResult(result);
  }

  @override
  Future<PagedResult<TrashedComic>> fetchTrashedPage(
    PageRequest request,
  ) async {
    final rust.PagedTrashedComicResultFrbDto page = await guardFrb(
      () => rust.fetchTrashedComicsPageFrb(
        request: mapTrashPageRequest(
          page: request.page,
          pageSize: request.pageSize,
        ),
      ),
      fallbackMessage: '读取已删除漫画失败',
    );
    return mapTrashedComicsPage(page);
  }

  @override
  Future<TrashedComicCounts> countTrashed() async {
    final rust.TrashedComicCountsFrbDto counts = await guardFrb(
      rust.countTrashedComicsFrb,
      fallbackMessage: '统计已删除漫画失败',
    );
    return mapTrashedComicCounts(counts);
  }

  @override
  Future<List<String>> listTrashedIds() =>
      guardFrb(rust.listTrashedComicIdsFrb, fallbackMessage: '读取已删除漫画失败');
}
