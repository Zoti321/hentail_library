import 'package:hentai_library/features/library_browse/domain/library_comic_grouping.dart';
import 'package:hentai_library/shared/domain/library/library_comic_filter.dart';
import 'package:hentai_library/shared/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';

/// Library browse 的 Comic 目录计数、分页与搜索。
abstract class ComicCatalogRepository {
  Future<int> countAll();

  Future<PagedResult<Comic>> fetchComicsPage({
    required PageRequest request,
    required LibraryComicFilter filter,
    required LibraryComicGrouping grouping,
    required LibraryComicSortOption sortOption,
  });

  /// 关键词搜索（数据库命中），由上层决定是否再应用额外业务过滤。
  Future<List<Comic>> searchByKeyword(String keyword);

  /// 关键词分页搜索。
  Future<PagedResult<Comic>> searchByKeywordPage({
    required String keyword,
    required PageRequest request,
  });

  /// 元数据表达式搜索（每 token 匹配标签名或作者名），由上层决定是否再应用额外业务过滤。
  Future<List<Comic>> searchByMetadataExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  });

  /// 元数据表达式分页搜索。
  Future<PagedResult<Comic>> searchByMetadataExpressionPage({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
    required PageRequest request,
  });
}
