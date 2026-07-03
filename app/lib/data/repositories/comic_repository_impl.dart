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
  Stream<void> watchChanges() => rust.watchComicChanges().map((int _) {});

  @override
  Future<int> countAll() async => rust.countAllComicsFrb().toInt();

  @override
  Future<List<Comic>> getAll() async {
    final int total = await countAll();
    if (total <= 0) {
      return <Comic>[];
    }
    final rust.PagedComicResultDto page = rust.fetchComicsPageFrb(
      request: rust.PageRequestDto(page: 1, pageSize: total),
      filter: unrestrictedListFilter(),
      sort: const rust.ComicSortOptionDto(descending: false),
    );
    return page.items.map(mapRustComic).toList();
  }

  @override
  Future<PagedResult<Comic>> fetchComicsPage({
    required PageRequest request,
    required LibraryComicFilter filter,
    required LibraryComicSortOption sortOption,
  }) async {
    final rust.PagedComicResultDto page = rust.fetchComicsPageFrb(
      request: mapPageRequest(request),
      filter: mapLibraryFilter(filter),
      sort: mapSortOption(sortOption),
    );
    return mapPagedResult(page);
  }

  @override
  Future<Comic?> findById(String comicId) async {
    final rust.ComicDto? dto = rust.findComicByIdFrb(comicId: comicId);
    return dto == null ? null : mapRustComic(dto);
  }

  @override
  Future<void> deleteByIds(List<String> comicIds) async {
    rust.deleteComicsByIdsFrb(comicIds: comicIds);
  }

  @override
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    List<Author>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
  }) async {
    rust.updateComicUserMetaFrb(
      comicId: comicId,
      meta: rust.UpdateComicUserMetaFrbDto(
        title: title,
        contentRating: contentRating?.name,
        authors: authors?.map((Author a) => a.name).toList(),
        tags: tags?.map((Tag t) => t.name).toList(),
      ),
    );
  }

  @override
  Future<List<Comic>> searchByKeyword(String keyword) async {
    return rust.searchByKeywordFrb(keyword: keyword).map(mapRustComic).toList();
  }

  @override
  Future<List<Comic>> searchByTagExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  }) async {
    return rust
        .searchByTagExpressionFrb(
          mustInclude: mustInclude.toList(),
          optionalOr: optionalOr.toList(),
          mustExclude: mustExclude.toList(),
        )
        .map(mapRustComic)
        .toList();
  }
}
