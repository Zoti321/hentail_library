import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart'
    as db;
import 'package:hentai_library/domain/entity/comic/author.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:hentai_library/domain/util/comic_scan_diff.dart';
import 'package:hentai_library/domain/repository/comic_repo.dart';
import 'package:hentai_library/domain/repository/series_repo.dart';
import 'package:hentai_library/domain/repository/reading_history_repo.dart';
import 'package:hentai_library/domain/usecases/purge_comics_side_effects.dart';
import 'package:drift/drift.dart';

/// 漫画主表与标签的持久化；**跨聚合**（阅读历史、系列）的删除/替换流程请放在
/// [domain/usecases]（例如 [purgeComicsFromApp]、[replaceByScan] 内已编排的 purge），
/// 避免在本类中继续堆叠多仓储协调逻辑。
class ComicRepositoryImpl implements ComicRepository {
  ComicRepositoryImpl(
    this._comicDao, {
    required ReadingHistoryRepository readingHistory,
    required SeriesRepository librarySeries,
  }) : _readingHistory = readingHistory,
       _librarySeries = librarySeries;

  final ComicDao _comicDao;
  final ReadingHistoryRepository _readingHistory;
  final SeriesRepository _librarySeries;

  Future<List<Comic>> _mapRows(List<db.DbComic> rows) async {
    final ids = rows.map((e) => e.comicId);
    final tagMap = await _comicDao.getTagNamesForComics(ids);
    final authorMap = await _comicDao.getAuthorNamesForComics(ids);
    return rows.map((r) {
      final tagNames = tagMap[r.comicId] ?? const <String>[];
      final authorNames = authorMap[r.comicId] ?? const <String>[];
      return Comic(
        comicId: r.comicId,
        path: r.path,
        resourceType: r.resourceType,
        title: r.title,
        authors: authorNames.map((n) => Author(name: n)).toList(),
        contentRating: r.contentRating,
        tags: tagNames.map((n) => Tag(name: n)).toList(),
        pageCount: r.pageCount,
      );
    }).toList();
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
    if (row == null) return null;
    final tagNames = await _comicDao.getTagNamesForComic(comicId);
    final authorNames = await _comicDao.getAuthorNamesForComic(comicId);
    return Comic(
      comicId: row.comicId,
      path: row.path,
      resourceType: row.resourceType,
      title: row.title,
      authors: authorNames.map((n) => Author(name: n)).toList(),
      contentRating: row.contentRating,
      tags: tagNames.map((n) => Tag(name: n)).toList(),
    );
  }

  @override
  Future<void> upsertMany(List<Comic> comics) async {
    final companions = comics
        .map(
          (c) => db.ComicsCompanion.insert(
            comicId: c.comicId,
            path: c.path,
            resourceType: c.resourceType,
            title: c.title,
            contentRating: Value(c.contentRating),
            pageCount: Value(c.pageCount),
          ),
        )
        .toList();

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
  Future<ComicReplaceByScanResult> replaceByScan(
    List<Comic> scanned,
  ) async {
    final unique = dedupeScannedByComicId(scanned);
    final scannedIds = unique.keys.toSet();

    final existing = await getAll();
    final existingById = {for (final c in existing) c.comicId: c};
    final existingIds = existingById.keys.toSet();

    final idDiff = computeComicScanIdDiff(
      existingIds: existingIds,
      scannedIds: scannedIds,
    );

    if (idDiff.removedIds.isNotEmpty) {
      await purgeComicsFromApp(
        libraryComics: this,
        readingHistory: _readingHistory,
        librarySeries: _librarySeries,
        comicIds: idDiff.removedIds,
      );
    }

    final toUpsert = <Comic>[];
    for (final e in unique.entries) {
      final id = e.key;
      final row = e.value;
      if (idDiff.addedIds.contains(id)) {
        toUpsert.add(row);
      } else {
        final prior = existingById[id]!;
        toUpsert.add(mergeKeptScanWithExisting(row, prior));
      }
    }

    await upsertMany(toUpsert);

    return (
      removedCount: idDiff.removedIds.length,
      addedCount: idDiff.addedIds.length,
      keptCount: idDiff.keptIds.length,
    );
  }
}
