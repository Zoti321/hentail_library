import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';

/// 漫画主表与标签的持久化；读写均经 Rust/SeaORM。
abstract class ComicRepository {
  Future<List<Comic>> getAll();

  Future<int> countAll();

  Future<Comic?> findById(String comicId);

  Future<PagedResult<Comic>> fetchComicsPage({
    required PageRequest request,
    required LibraryComicFilter filter,
    required LibraryComicSortOption sortOption,
  });

  Future<void> deleteByIds(List<String> comicIds);

  /// 用户编辑覆盖解析值：title/authors/contentRating/tags 等。
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    List<Author>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
  });

  /// 关键词搜索（数据库命中），由上层决定是否再应用额外业务过滤。
  Future<List<Comic>> searchByKeyword(String keyword);

  /// 标签表达式搜索（数据库命中），由上层决定是否再应用额外业务过滤。
  Future<List<Comic>> searchByTagExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  });
}
