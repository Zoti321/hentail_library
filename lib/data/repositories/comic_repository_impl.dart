import 'package:drift/drift.dart';
import 'package:hentai_library/data/database/dao/dao.dart';
import 'package:hentai_library/data/database/database.dart' as db;
import 'package:hentai_library/data/mappers/mapping.dart';
import 'package:hentai_library/domain/models/entity/comic/author.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/tag.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';

typedef _ComicScanIdDiff = ({
  Set<String> removedIds,
  Set<String> addedIds,
  Set<String> keptIds,
});

/// 漫画主表与标签的持久化；跨聚合删除请经 [DeleteComicsUseCase]。
class ComicRepositoryImpl implements ComicRepository {
  ComicRepositoryImpl(this._comicDao, this._searchDao);

  final ComicDao _comicDao;
  final SearchDao _searchDao;

  Future<List<Comic>> _mapRows(List<db.DbComic> rows) async {
    final Iterable<String> ids = rows.map((db.DbComic e) => e.comicId);
    final Map<String, List<String>> tagMap = await _comicDao
        .getTagNamesForComics(ids);
    final Map<String, List<String>> authorMap = await _comicDao
        .getAuthorNamesForComics(ids);
    return rows
        .map(
          (db.DbComic row) => row.toEntity(
            authorNames: authorMap[row.comicId] ?? const <String>[],
            tagNames: tagMap[row.comicId] ?? const <String>[],
          ),
        )
        .toList();
  }

  Future<List<Comic>> _loadComicsOrderedByIds(List<String> comicIds) async {
    if (comicIds.isEmpty) {
      return <Comic>[];
    }
    final List<db.DbComic> rows = await _comicDao.getComicsByIds(comicIds);
    final List<Comic> mapped = await _mapRows(rows);
    final Map<String, Comic> comicsById = <String, Comic>{
      for (final Comic comic in mapped) comic.comicId: comic,
    };
    final List<Comic> ordered = <Comic>[];
    for (final String comicId in comicIds) {
      final Comic? comic = comicsById[comicId];
      if (comic != null) {
        ordered.add(comic);
      }
    }
    return ordered;
  }

  @override
  Stream<List<Comic>> watchAll() {
    return _comicDao.watchAllComics().asyncMap(_mapRows);
  }

  @override
  Future<List<Comic>> getAll() async {
    final rows = await _comicDao.getAllComics();
    return _mapRows(rows);
  }

  @override
  Future<Comic?> findById(String comicId) async {
    final row = await _comicDao.findById(comicId);
    if (row == null) {
      return null;
    }
    final List<String> tagNames = await _comicDao.getTagNamesForComic(comicId);
    final List<String> authorNames = await _comicDao.getAuthorNamesForComic(
      comicId,
    );
    return row.toEntity(authorNames: authorNames, tagNames: tagNames);
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
    final toUpsert = <Comic>[];
    for (final e in unique.entries) {
      final id = e.key;
      final row = e.value;
      if (idDiff.addedIds.contains(id)) {
        toUpsert.add(row);
      } else {
        final prior = existingById[id]!;
        toUpsert.add(_mergeKeptScanWithExisting(row, prior));
      }
    }
    return (
      removedIds: idDiff.removedIds.toList(),
      addedCount: idDiff.addedIds.length,
      keptCount: idDiff.keptIds.length,
      toUpsert: toUpsert,
    );
  }

  @override
  Future<List<Comic>> searchByKeyword(String keyword) async {
    final List<String> comicIds = await _searchDao.searchComicIdsByKeyword(
      keyword,
    );
    return _loadComicsOrderedByIds(comicIds);
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
    return _loadComicsOrderedByIds(comicIds);
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

  Comic _mergeKeptScanWithExisting(Comic scanned, Comic existing) {
    return existing.copyWith(
      path: scanned.path,
      resourceType: scanned.resourceType,
    );
  }
}
