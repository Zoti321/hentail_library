import 'package:hentai_library/features/comic/data/comic_entity_mapper.dart';
import 'package:hentai_library/shared/data/frb/frb_call_guard.dart';
import 'package:hentai_library/features/comic/data/comic_frb_mapper.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_catalog_repository.dart';
import 'package:hentai_library/features/comic/domain/value_objects/library_comic_grouping.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_user_metadata_repository.dart';
import 'package:hentai_library/features/comic/domain/value_objects/library_comic_filter.dart';
import 'package:hentai_library/features/comic/domain/value_objects/library_comic_sort_option.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

/// Sentinel passed to Rust when the user clears published date.
const int _kComicPublishedAtClearSentinel = -1;

/// 漫画主表持久化；读写均经 Rust/SeaORM。
class ComicRepositoryImpl
    implements
        ComicLookupRepository,
        ComicCatalogRepository,
        ComicUserMetadataRepository {
  const ComicRepositoryImpl();

  @override
  Future<int> countAll() async => guardFrb(
    () async => (await rust.countAllComicsFrb()).toInt(),
    fallbackMessage: '统计漫画数量失败',
  );

  @override
  Future<PagedResult<Comic>> fetchComicsPage({
    required PageRequest request,
    required LibraryComicFilter filter,
    required LibraryComicGrouping grouping,
    required LibraryComicSortOption sortOption,
  }) async {
    final rust.PagedComicResultDto page = await guardFrb(
      () => rust.fetchComicsPageFrb(
        request: mapPageRequest(request),
        filter: mapLibraryFilter(filter),
        grouping: mapComicGrouping(grouping),
        sort: mapSortOption(sortOption),
      ),
      fallbackMessage: '读取漫画分页失败',
    );
    return mapPagedResult(page);
  }

  @override
  Future<
    PagedResult<({String comicId, String title, int pageCount, String path})>
  >
  fetchComicsBrowsePage({
    required PageRequest request,
    required LibraryComicFilter filter,
    required LibraryComicGrouping grouping,
    required LibraryComicSortOption sortOption,
  }) async {
    final rust.PagedComicBrowseResultDto page = await guardFrb(
      () => rust.fetchComicsBrowsePageFrb(
        request: mapPageRequest(request),
        filter: mapLibraryFilter(filter),
        grouping: mapComicGrouping(grouping),
        sort: mapSortOption(sortOption),
      ),
      fallbackMessage: '读取漫画浏览分页失败',
    );
    return PagedResult<
      ({String comicId, String title, int pageCount, String path})
    >(
      items: <({String comicId, String title, int pageCount, String path})>[
        for (final rust.ComicBrowseItemDto item in page.items)
          (
            comicId: item.comicId,
            title: item.title,
            pageCount: item.pageCount,
            path: item.path,
          ),
      ],
      page: page.page,
      pageSize: page.pageSize,
      totalCount: page.totalCount.toInt(),
    );
  }

  @override
  Future<Comic?> findById(String comicId) async {
    final rust.ComicDto? dto = await guardFrb(
      () => rust.findComicByIdFrb(comicId: comicId),
      fallbackMessage: '读取漫画失败',
    );
    return dto == null ? null : mapRustComic(dto);
  }

  @override
  Future<List<Comic>> findByIds(List<String> comicIds) async {
    if (comicIds.isEmpty) {
      return const <Comic>[];
    }
    final List<rust.ComicDto> rows = await guardFrb(
      () => rust.findComicsByIdsFrb(comicIds: comicIds),
      fallbackMessage: '批量读取漫画失败',
    );
    return rows.map(mapRustComic).toList();
  }

  @override
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    String? description,
    DateTime? publishedAt,
    bool clearPublishedAt = false,
    List<String>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
    List<String>? languages,
    List<String>? parodies,
    List<String>? characters,
  }) async {
    guardFrbSync(
      () => rust.updateComicUserMetaFrb(
        comicId: comicId,
        meta: rust.UpdateComicUserMetaFrbDto(
          title: title,
          contentRating: contentRating?.name,
          description: description,
          publishedAt: clearPublishedAt
              ? _kComicPublishedAtClearSentinel
              : publishedAt == null
              ? null
              : comicTimestampToMs(publishedAt),
          authors: authors,
          tags: tags?.map((Tag t) => t.name).toList(),
          languages: languages,
          parodies: parodies,
          characters: characters,
        ),
      ),
      fallbackMessage: '更新漫画元数据失败',
    );
  }

  @override
  Future<void> setMetaLocks(
    String comicId, {
    bool? title,
    bool? description,
    bool? publishedAt,
    bool? contentRating,
    bool? authors,
    bool? tags,
    bool? languages,
    bool? parodies,
    bool? characters,
  }) async {
    guardFrbSync(
      () => rust.setComicMetaLocksFrb(
        comicId: comicId,
        locks: rust.SetComicMetaLocksFrbDto(
          title: title,
          description: description,
          publishedAt: publishedAt,
          contentRating: contentRating,
          authors: authors,
          tags: tags,
          languages: languages,
          parodies: parodies,
          characters: characters,
        ),
      ),
      fallbackMessage: '更新漫画元数据锁失败',
    );
  }

  @override
  Future<List<Comic>> searchByKeyword({
    required String keyword,
    required String libraryId,
  }) async {
    final List<rust.ComicDto> rows = await guardFrb(
      () => rust.searchByKeywordFrb(keyword: keyword, libraryId: libraryId),
      fallbackMessage: '搜索漫画失败',
    );
    return rows.map(mapRustComic).toList();
  }

  @override
  Future<PagedResult<Comic>> searchByKeywordPage({
    required String keyword,
    required PageRequest request,
    required String libraryId,
  }) async {
    final rust.PagedComicResultDto page = await guardFrb(
      () => rust.searchByKeywordPageFrb(
        keyword: keyword,
        request: rust.PageRequestDto(
          page: request.page,
          pageSize: request.pageSize,
        ),
        libraryId: libraryId,
      ),
      fallbackMessage: '搜索漫画失败',
    );
    return mapPagedResult(page);
  }

  @override
  Future<List<Comic>> searchByMetadataExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
    required String libraryId,
  }) async {
    final List<rust.ComicDto> rows = await guardFrb(
      () => rust.searchByTagExpressionFrb(
        mustInclude: mustInclude.toList(),
        optionalOr: optionalOr.toList(),
        mustExclude: mustExclude.toList(),
        libraryId: libraryId,
      ),
      fallbackMessage: '按元数据搜索漫画失败',
    );
    return rows.map(mapRustComic).toList();
  }

  @override
  Future<PagedResult<Comic>> searchByMetadataExpressionPage({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
    required PageRequest request,
    required String libraryId,
  }) async {
    final rust.PagedComicResultDto page = await guardFrb(
      () => rust.searchByTagExpressionPageFrb(
        mustInclude: mustInclude.toList(),
        optionalOr: optionalOr.toList(),
        mustExclude: mustExclude.toList(),
        request: rust.PageRequestDto(
          page: request.page,
          pageSize: request.pageSize,
        ),
        libraryId: libraryId,
      ),
      fallbackMessage: '按元数据搜索漫画失败',
    );
    return mapPagedResult(page);
  }
}

rust.ComicGroupingDto mapComicGrouping(LibraryComicGrouping grouping) =>
    switch (grouping) {
      LibraryComicGrouping.none => rust.ComicGroupingDto.none,
      LibraryComicGrouping.bySeries => rust.ComicGroupingDto.bySeries,
    };
