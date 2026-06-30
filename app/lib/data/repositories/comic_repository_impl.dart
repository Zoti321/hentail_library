import 'package:drift/drift.dart';
import 'package:hentai_library/data/database/dao/dao.dart';
import 'package:hentai_library/data/database/database.dart' as db;
import 'package:hentai_library/data/repositories/comic_frb_mapper.dart';
import 'package:hentai_library/data/repositories/comic_scan_merge.dart';
import 'package:hentai_library/domain/library/library_comic_filter.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/data/services/comic/thumbnail/comic_thumbnail_generation_policy.dart';
import 'package:hentai_library/data/services/comic/thumbnail/comic_thumbnail_generator.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;

typedef _ComicScanIdDiff = ({
  Set<String> removedIds,
  Set<String> addedIds,
  Set<String> keptIds,
});

/// 漫画主表与标签的持久化；读路径经 Rust/SeaORM，写路径仍用 Drift（#14）。
class ComicRepositoryImpl implements ComicRepository {
  ComicRepositoryImpl(
    this._comicDao,
    this._searchDao,
    this._thumbnailRepository,
  );

  final ComicDao _comicDao;
  final SearchDao _searchDao;
  final ComicThumbnailRepository _thumbnailRepository;

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
  Future<void> upsertMany(List<Comic> comics) async {
    final companions = comics.map((c) {
      return db.ComicsCompanion.insert(
        comicId: c.comicId,
        path: c.path,
        resourceType: c.resourceType,
        title: c.title,
        contentRating: Value(c.contentRating),
        pageCount: Value(c.pageCount),
      );
    }).toList();

    await _comicDao.upsertMany(companions);

    for (final c in comics) {
      await _comicDao.replaceComicAuthors(
        c.comicId,
        c.authors.map((a) => a.name).toList(),
      );
      await _comicDao.replaceComicTags(
        c.comicId,
        c.tags.map((t) => t.name).toList(),
      );
    }
  }

  @override
  Future<void> deleteByIds(List<String> comicIds) async {
    await _comicDao.deleteByIds(comicIds);
  }

  @override
  Future<void> updateUserMeta(
    String comicId, {
    String? title,
    List<Author>? authors,
    ContentRating? contentRating,
    List<Tag>? tags,
  }) async {
    await _comicDao.updateUserMeta(
      comicId,
      title: Value.absentIfNull(title),
      contentRating: contentRating == null
          ? const Value.absent()
          : Value(contentRating),
    );
    if (authors != null) {
      await _comicDao.replaceComicAuthors(
        comicId,
        authors.map((e) => e.name).toList(),
      );
    }
    if (tags != null) {
      await _comicDao.replaceComicTags(
        comicId,
        tags.map((e) => e.name).toList(),
      );
    }
  }

  @override
  Future<ComicScanReplacePlan> buildScanReplacePlan(List<Comic> scanned) async {
    final unique = _dedupeScannedByComicId(scanned);
    final scannedIds = unique.keys.toSet();
    final existing = await getAll();
    final existingById = {for (final c in existing) c.comicId: c};
    final existingIds = existingById.keys.toSet();
    final idDiff = _computeComicScanIdDiff(
      existingIds: existingIds,
      scannedIds: scannedIds,
    );
    final List<String> thumbnailInvalidatedComicIds = <String>[];
    final toUpsert = <Comic>[];
    for (final e in unique.entries) {
      final id = e.key;
      final row = e.value;
      if (idDiff.addedIds.contains(id)) {
        toUpsert.add(row);
      } else {
        final prior = existingById[id]!;
        if (prior.path != row.path || prior.resourceType != row.resourceType) {
          thumbnailInvalidatedComicIds.add(id);
        }
        toUpsert.add(mergeKeptScanWithExisting(row, prior));
      }
    }
    return (
      removedIds: idDiff.removedIds.toList(),
      addedCount: idDiff.addedIds.length,
      keptCount: idDiff.keptIds.length,
      toUpsert: toUpsert,
      thumbnailInvalidatedComicIds: thumbnailInvalidatedComicIds,
      thumbnailGenerationTargets: await _buildThumbnailGenerationTargets(
        toUpsert: toUpsert,
        addedIds: idDiff.addedIds,
        keptIds: idDiff.keptIds,
        invalidatedIds: thumbnailInvalidatedComicIds.toSet(),
      ),
    );
  }

  Future<List<Comic>> _buildThumbnailGenerationTargets({
    required List<Comic> toUpsert,
    required Set<String> addedIds,
    required Set<String> keptIds,
    required Set<String> invalidatedIds,
  }) async {
    final List<Comic> targets = <Comic>[];
    for (final Comic comic in toUpsert) {
      if (!canGenerateComicThumbnail(comic.resourceType)) {
        continue;
      }
      final String id = comic.comicId;
      if (addedIds.contains(id) || invalidatedIds.contains(id)) {
        targets.add(comic);
        continue;
      }
      if (keptIds.contains(id) &&
          await needsComicThumbnailGeneration(
            comic: comic,
            repository: _thumbnailRepository,
          )) {
        targets.add(comic);
      }
    }
    return targets;
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
    final List<String> comicIds = await _searchDao
        .searchComicIdsByTagExpression(
          mustInclude: mustInclude,
          optionalOr: optionalOr,
          mustExclude: mustExclude,
        );
    final List<Comic> ordered = <Comic>[];
    for (final String comicId in comicIds) {
      final Comic? comic = await findById(comicId);
      if (comic != null) {
        ordered.add(comic);
      }
    }
    return ordered;
  }

  Map<String, Comic> _dedupeScannedByComicId(List<Comic> scanned) {
    final map = <String, Comic>{};
    for (final Comic comic in scanned) {
      map[comic.comicId] = comic;
    }
    return map;
  }

  _ComicScanIdDiff _computeComicScanIdDiff({
    required Set<String> existingIds,
    required Set<String> scannedIds,
  }) {
    return (
      removedIds: existingIds.difference(scannedIds),
      addedIds: scannedIds.difference(existingIds),
      keptIds: existingIds.intersection(scannedIds),
    );
  }
}
