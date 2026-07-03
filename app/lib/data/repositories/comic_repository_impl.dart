import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/repositories/comic_frb_mapper.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

/// 漫画主表持久化；读写均经 Rust/SeaORM。
class ComicRepositoryImpl implements ComicRepository {
  const ComicRepositoryImpl();

  @override
  Stream<void> watchChanges() => guardFrbStream(
    () => rust.watchComicChanges().map((int _) {}),
    fallbackMessage: '监听漫画变更失败',
  );

  @override
  Future<int> countAll() async => guardFrbSync(
    () => rust.countAllComicsFrb().toInt(),
    fallbackMessage: '统计漫画数量失败',
  );

  @override
  Future<List<Comic>> getAll() async {
    final int total = await countAll();
    if (total <= 0) {
      return <Comic>[];
    }
    final rust.PagedComicResultDto page = guardFrbSync(
      () => rust.fetchComicsPageFrb(
        request: rust.PageRequestDto(page: 1, pageSize: total),
        filter: unrestrictedListFilter(),
        sort: const rust.ComicSortOptionDto(descending: false),
      ),
      fallbackMessage: '读取漫画列表失败',
    );
    return page.items.map(mapRustComic).toList();
  }

  @override
  Future<PagedResult<Comic>> fetchComicsPage({
    required PageRequest request,
    required LibraryComicFilter filter,
    required LibraryComicSortOption sortOption,
  }) async {
    final rust.PagedComicResultDto page = guardFrbSync(
      () => rust.fetchComicsPageFrb(
        request: mapPageRequest(request),
        filter: mapLibraryFilter(filter),
        sort: mapSortOption(sortOption),
      ),
      fallbackMessage: '读取漫画分页失败',
    );
    return mapPagedResult(page);
  }

  @override
  Future<Comic?> findById(String comicId) async {
    final rust.ComicDto? dto = guardFrbSync(
      () => rust.findComicByIdFrb(comicId: comicId),
      fallbackMessage: '读取漫画失败',
    );
    return dto == null ? null : mapRustComic(dto);
  }

  @override
  Future<void> deleteByIds(List<String> comicIds) async {
    guardFrbSync(
      () => rust.deleteComicsByIdsFrb(comicIds: comicIds),
      fallbackMessage: '删除漫画失败',
    );
  }

  @override
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    List<Author>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
  }) async {
    guardFrbSync(
      () => rust.updateComicUserMetaFrb(
        comicId: comicId,
        meta: rust.UpdateComicUserMetaFrbDto(
          title: title,
          contentRating: contentRating?.name,
          authors: authors?.map((Author a) => a.name).toList(),
          tags: tags?.map((Tag t) => t.name).toList(),
        ),
      ),
      fallbackMessage: '更新漫画元数据失败',
    );
  }

  @override
  Future<List<Comic>> searchByKeyword(String keyword) async {
    return guardFrbSync(
      () => rust.searchByKeywordFrb(keyword: keyword).map(mapRustComic).toList(),
      fallbackMessage: '搜索漫画失败',
    );
  }

  @override
  Future<List<Comic>> searchByTagExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  }) async {
    return guardFrbSync(
      () => rust
          .searchByTagExpressionFrb(
            mustInclude: mustInclude.toList(),
            optionalOr: optionalOr.toList(),
            mustExclude: mustExclude.toList(),
          )
          .map(mapRustComic)
          .toList(),
      fallbackMessage: '按标签搜索漫画失败',
    );
  }
}
