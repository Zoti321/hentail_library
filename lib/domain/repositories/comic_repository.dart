import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';

/// Library sync 扫描 diff 计划：调用方须先对 [removedIds] 执行 [DeleteComicsUseCase]。
typedef ComicScanReplacePlan = ({
  List<String> removedIds,
  int addedCount,
  int keptCount,
  List<Comic> toUpsert,
  List<String> thumbnailInvalidatedComicIds,
  List<Comic> thumbnailGenerationTargets,
});

abstract class ComicRepository {
  /// 漫画表变更通知（不推送全量数据）。
  Stream<void> watchChanges();

  Future<List<Comic>> getAll();

  Future<int> countAll();

  Future<Comic?> findById(String comicId);

  Future<PagedResult<Comic>> fetchComicsPage({
    required PageRequest request,
    required LibraryComicFilter filter,
    required LibraryComicSortOption sortOption,
  });

  /// 用于扫描导入（写入/更新）。
  Future<void> upsertMany(List<Comic> comics);

  Future<void> deleteByIds(List<String> comicIds);

  /// 用户编辑覆盖解析值：title/authors/contentRating/tags 等。
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    List<Author>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
  });

  /// 计算扫描 diff 与待 upsert 列表；不删除 [ComicScanReplacePlan.removedIds]。
  Future<ComicScanReplacePlan> buildScanReplacePlan(List<Comic> scanned);

  /// 关键词搜索（数据库命中），由上层决定是否再应用额外业务过滤。
  Future<List<Comic>> searchByKeyword(String keyword);

  /// 标签表达式搜索（数据库命中），由上层决定是否再应用额外业务过滤。
  Future<List<Comic>> searchByTagExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  });
}
