import 'package:hentai_library/shared/data/frb/frb_call_guard.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as comic_rust;
import 'package:hentai_library/src/rust/api/comic_trash.dart' as rust;

/// Comic trash FRB 薄封装（owner：`src/rust/api/comic_trash.dart`）。
class ComicTrashFrbAdapter {
  const ComicTrashFrbAdapter();

  Future<void> trashByIds(List<String> comicIds) => guardFrb(
        () => rust.trashComicsFrb(comicIds: comicIds),
        fallbackMessage: '移入已删除失败',
      );

  Future<void> restoreByIds(List<String> comicIds) => guardFrb(
        () => rust.restoreComicsFrb(comicIds: comicIds),
        fallbackMessage: '恢复漫画失败',
      );

  Future<rust.ComicPurgeResultFrbDto> purgeByIds(List<String> comicIds) =>
      guardFrb(
        () => rust.purgeComicsFrb(comicIds: comicIds),
        fallbackMessage: '永久删除漫画失败',
      );

  Future<rust.PagedTrashedComicResultFrbDto> fetchTrashedPage(
    comic_rust.PageRequestDto request,
  ) =>
      guardFrb(
        () => rust.fetchTrashedComicsPageFrb(request: request),
        fallbackMessage: '读取已删除漫画失败',
      );

  Future<rust.TrashedComicCountsFrbDto> countTrashed() => guardFrb(
        rust.countTrashedComicsFrb,
        fallbackMessage: '统计已删除漫画失败',
      );

  Future<List<String>> listTrashedIds() => guardFrb(
        rust.listTrashedComicIdsFrb,
        fallbackMessage: '读取已删除漫画失败',
      );
}
