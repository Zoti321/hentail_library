import 'package:hentai_library/shared/domain/models/read_models/trashed_comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';

/// Comic trash / Comic restore / Comic purge，以及「已删除」列表。
abstract class ComicTrashRepository {
  /// Comic trash：从所有浏览面隐藏，库记录与 Resource 保留。
  Future<void> trashByIds(List<String> comicIds);

  /// Comic restore：清除 trash 标记。
  Future<void> restoreByIds(List<String> comicIds);

  /// Comic purge：仅接受已 trash 的 id，逐本处理；失败者保持 trash。
  Future<ComicPurgeResult> purgeByIds(List<String> comicIds);

  /// 跨全部 Library 的「已删除」分页，按删除时间倒序。
  Future<PagedResult<TrashedComic>> fetchTrashedPage(PageRequest request);

  Future<TrashedComicCounts> countTrashed();

  Future<List<String>> listTrashedIds();
}
