import 'package:drift/drift.dart';
import 'package:hentai_library/database/dao/dao.dart';
import 'package:hentai_library/database/database.dart' as db;
import 'package:hentai_library/usecases/purge_comics_side_effects.dart';
import 'package:hentai_library/model/entity/comic/author.dart';
import 'package:hentai_library/model/entity/comic/comic.dart';
import 'package:hentai_library/model/entity/comic/tag.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:hentai_library/repository/reading_history_repository.dart';
import 'package:hentai_library/repository/series_repository.dart';

/// [replaceByScan] 应用结果统计（供 UI 进度等）。
typedef ComicReplaceByScanResult = ({
  int removedCount,
  int addedCount,
  int keptCount,
});

abstract class ComicRepository {
  Stream<List<Comic>> watchAll();

  Future<List<Comic>> getAll();

  Future<Comic?> findById(String comicId);

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

  /// 扫描 diff：删除库中本次未出现的条目并清理关联；新增与保留条目写入（保留合并用户元数据）。
  Future<ComicReplaceByScanResult> replaceByScan(List<Comic> scanned);

  /// 关键词搜索（数据库命中），由上层决定是否再应用额外业务过滤。
  Future<List<Comic>> searchByKeyword(String keyword);

  /// 标签表达式搜索（数据库命中），由上层决定是否再应用额外业务过滤。
  Future<List<Comic>> searchByTagExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  });
}

typedef _ComicScanIdDiff = ({
  Set<String> removedIds,
  Set<String> addedIds,
  Set<String> keptIds,
});

/// 漫画主表与标签的持久化；**跨聚合**（阅读历史、系列）的删除/替换流程请放在
/// [domain/usecases]（例如 [purgeComicsFromApp]、[replaceByScan] 内已编排的 purge），
/// 避免在本类中继续堆叠多仓储协调逻辑。
class ComicRepositoryImpl implements ComicRepository {
  ComicRepositoryImpl(
    this._comicDao,
    this._searchDao, {
    required ReadingHistoryRepository readingHistory,
    required SeriesRepository librarySeries,
  }) : _readingHistory = readingHistory,
       _librarySeries = librarySeries;

  final ComicDao _comicDao;
  final SearchDao _searchDao;
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
  Future<ComicReplaceByScanResult> replaceByScan(List<Comic> scanned) async {
    final unique = _dedupeScannedByComicId(scanned);
    final scannedIds = unique.keys.toSet();

    final existing = await getAll();
    final existingById = {for (final c in existing) c.comicId: c};
    final existingIds = existingById.keys.toSet();

    final idDiff = _computeComicScanIdDiff(
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
        toUpsert.add(_mergeKeptScanWithExisting(row, prior));
      }
    }

    await upsertMany(toUpsert);

    return (
      removedCount: idDiff.removedIds.length,
      addedCount: idDiff.addedIds.length,
      keptCount: idDiff.keptIds.length,
    );
  }

  @override
  Future<List<Comic>> searchByKeyword(String keyword) async {
    final List<String> comicIds = await _searchDao.searchComicIdsByKeyword(
      keyword,
    );
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
