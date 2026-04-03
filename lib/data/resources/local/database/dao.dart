import 'package:drift/drift.dart';
import 'package:hentai_library/domain/util/enums.dart';

import 'database.dart';

part 'dao.g.dart';

@DriftAccessor(tables: [LibraryComics, LibraryComicTags])
class LibraryComicDao extends DatabaseAccessor<AppDatabase>
    with _$LibraryComicDaoMixin {
  LibraryComicDao(super.db);

  Stream<List<LibraryComic>> watchAllComics() => select(libraryComics).watch();

  Future<List<LibraryComic>> getAllComics() => select(libraryComics).get();

  /// 仅 comicId 列，用于大库 diff 等场景（不加载 tags）。
  Future<List<String>> getAllComicIds() async {
    final rows = await select(libraryComics).get();
    return rows.map((r) => r.comicId).toList();
  }

  Future<LibraryComic?> findById(String comicId) {
    return (select(
      libraryComics,
    )..where((t) => t.comicId.equals(comicId))).getSingleOrNull();
  }

  Future<void> upsertMany(List<LibraryComicsCompanion> companions) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(libraryComics, companions);
    });
  }

  Future<int> deleteByIds(List<String> comicIds) {
    if (comicIds.isEmpty) return Future.value(0);
    return (delete(libraryComics)..where((t) => t.comicId.isIn(comicIds))).go();
  }

  Future<void> replaceComicTags(String comicId, List<String> tagNames) async {
    await transaction(() async {
      await (delete(
        libraryComicTags,
      )..where((t) => t.comicId.equals(comicId))).go();
      if (tagNames.isEmpty) return;
      final rows = tagNames
          .toSet()
          .map(
            (name) => LibraryComicTagsCompanion.insert(
              comicId: comicId,
              tagName: name,
            ),
          )
          .toList();
      await batch((b) => b.insertAll(libraryComicTags, rows));
    });
  }

  Future<List<String>> getTagNamesForComic(String comicId) async {
    final rows = await (select(
      libraryComicTags,
    )..where((t) => t.comicId.equals(comicId))).get();
    return rows.map((e) => e.tagName).toList();
  }

  Future<Map<String, List<String>>> getTagNamesForComics(
    Iterable<String> comicIds,
  ) async {
    final ids = comicIds.toList();
    if (ids.isEmpty) return {};
    final rows = await (select(
      libraryComicTags,
    )..where((t) => t.comicId.isIn(ids))).get();
    final map = <String, List<String>>{};
    for (final r in rows) {
      (map[r.comicId] ??= <String>[]).add(r.tagName);
    }
    return map;
  }

  Future<int> updateUserMeta(
    String comicId, {
    Value<String>? title,
    Value<List<String>>? authors,
    Value<ContentRating>? contentRating,
  }) {
    return (update(
      libraryComics,
    )..where((t) => t.comicId.equals(comicId))).write(
      LibraryComicsCompanion(
        title: title ?? const Value.absent(),
        authorsJson: authors ?? const Value.absent(),
        contentRating: contentRating ?? const Value.absent(),
      ),
    );
  }
}

@DriftAccessor(tables: [LibrarySeries, LibrarySeriesItems])
class LibrarySeriesDao extends DatabaseAccessor<AppDatabase>
    with _$LibrarySeriesDaoMixin {
  LibrarySeriesDao(super.db);

  Stream<List<LibrarySery>> watchAllSeries() => select(librarySeries).watch();

  Future<List<LibrarySery>> getAllSeries() => select(librarySeries).get();

  Future<LibrarySery?> findByName(String name) {
    return (select(
      librarySeries,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  Future<void> createSeries(LibrarySeriesCompanion companion) async {
    await into(
      librarySeries,
    ).insert(companion, mode: InsertMode.insertOrIgnore);
  }

  Future<int> renameSeries({required String name, required String newName}) {
    return (update(librarySeries)..where((t) => t.name.equals(name))).write(
      LibrarySeriesCompanion(name: Value(newName)),
    );
  }

  Future<int> deleteSeries(String seriesName) {
    return (delete(
      librarySeries,
    )..where((t) => t.name.equals(seriesName))).go();
  }

  Future<void> assignComicExclusive({
    required String comicId,
    required String targetSeriesName,
    required int sortOrder,
  }) async {
    await transaction(() async {
      await (delete(
        librarySeriesItems,
      )..where((t) => t.comicId.equals(comicId))).go();

      await into(librarySeriesItems).insertOnConflictUpdate(
        LibrarySeriesItemsCompanion.insert(
          seriesName: targetSeriesName,
          comicId: comicId,
          sortOrder: sortOrder,
        ),
      );
    });
  }

  Future<int> removeComic(String comicId) {
    return (delete(
      librarySeriesItems,
    )..where((t) => t.comicId.equals(comicId))).go();
  }

  /// 批量移除系列归属（无 FK 指向 library_comics，需在删漫画前调用）。
  Future<int> removeComicsFromSeries(Iterable<String> comicIds) {
    final ids = comicIds.toList();
    if (ids.isEmpty) return Future.value(0);
    return (delete(librarySeriesItems)..where((t) => t.comicId.isIn(ids))).go();
  }

  Future<List<LibrarySeriesItem>> getItemsForSeries(String seriesName) {
    return (select(librarySeriesItems)
          ..where((t) => t.seriesName.equals(seriesName))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }
}

@DriftAccessor(tables: [LibraryTags, LibraryComicTags])
class LibraryTagDao extends DatabaseAccessor<AppDatabase>
    with _$LibraryTagDaoMixin {
  LibraryTagDao(super.db);

  Future<List<LibraryTag>> listAll() => select(libraryTags).get();

  Future<void> addTag(String name) async {
    await into(libraryTags).insert(
      LibraryTagsCompanion.insert(name: name),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<int> deleteByNames(List<String> names) {
    if (names.isEmpty) return Future.value(0);
    return (delete(libraryTags)..where((t) => t.name.isIn(names))).go();
  }

  Future<void> renameTag(String oldName, String newName) async {
    await transaction(() async {
      await into(libraryTags).insert(
        LibraryTagsCompanion.insert(name: newName),
        mode: InsertMode.insertOrIgnore,
      );

      await (update(libraryComicTags)..where((t) => t.tagName.equals(oldName)))
          .write(LibraryComicTagsCompanion(tagName: Value(newName)));

      await (delete(libraryTags)..where((t) => t.name.equals(oldName))).go();
    });
  }
}

@DriftAccessor(tables: [SavedPaths])
class SavedPathDao extends DatabaseAccessor<AppDatabase>
    with _$SavedPathDaoMixin {
  SavedPathDao(super.db);

  Future<List<SavedPath>> getAll() => select(savedPaths).get();

  Stream<List<SavedPath>> watchAll() => select(savedPaths).watch().distinct();

  Future<int> insert(SavedPathsCompanion companion) {
    return into(savedPaths).insert(
      companion,
      mode: InsertMode.insertOrIgnore,
      onConflict: DoNothing(),
    );
  }

  Future<int> deleteRow(String path) {
    return (delete(savedPaths)..where((t) => t.rawPath.equals(path))).go();
  }
}

@DriftAccessor(tables: [ReadingHistories])
class ReadingHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingHistoryDaoMixin {
  ReadingHistoryDao(super.db);

  Future<void> recordReading(ReadingHistoriesCompanion companion) async {
    await into(readingHistories).insert(
      companion,
      onConflict: DoUpdate(
        (old) => ReadingHistoriesCompanion.custom(
          lastReadTime: Variable(companion.lastReadTime.value),
          title: Variable(companion.title.value),
          coverUrl: Variable(companion.coverUrl.value),
          chapterId: companion.chapterId.present
              ? Variable(companion.chapterId.value)
              : null,
          pageIndex: companion.pageIndex.present
              ? Variable(companion.pageIndex.value)
              : null,
        ),
        target: [readingHistories.comicId],
      ),
    );
  }

  Future<ReadingHistory?> getReadingHistoryByComicId(String comicId) {
    return (select(
      readingHistories,
    )..where((t) => t.comicId.equals(comicId))).getSingleOrNull();
  }

  Stream<List<ReadingHistory>> watchAllHistory() {
    return (select(
      readingHistories,
    )..orderBy([(t) => OrderingTerm.desc(t.lastReadTime)])).watch();
  }

  Future<int> deleteByComicId(String comicId) {
    return (delete(
      readingHistories,
    )..where((t) => t.comicId.equals(comicId))).go();
  }

  Future<int> deleteByComicIds(Iterable<String> comicIds) {
    final ids = comicIds.toList();
    if (ids.isEmpty) return Future.value(0);
    return (delete(readingHistories)..where((t) => t.comicId.isIn(ids))).go();
  }

  Future<int> clearAllHistory() {
    return delete(readingHistories).go();
  }

  Future<void> clearExpiredHistory() async {
    final limitDate = DateTime.now().subtract(const Duration(days: 365));
    await (delete(
      readingHistories,
    )..where((t) => t.lastReadTime.isSmallerThanValue(limitDate))).go();
  }
}
