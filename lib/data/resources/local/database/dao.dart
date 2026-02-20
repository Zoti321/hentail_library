import 'package:drift/drift.dart';
import 'package:hentai_library/domain/util/enums.dart';

import 'database.dart';

part 'dao.g.dart';

@DriftAccessor(tables: [Comics, ComicTags])
class ComicDao extends DatabaseAccessor<AppDatabase> with _$ComicDaoMixin {
  ComicDao(super.db);

  Stream<List<DbComic>> watchAllComics() => select(comics).watch();

  Future<List<DbComic>> getAllComics() => select(comics).get();

  /// 仅 comicId 列，用于大库 diff 等场景（不加载 tags）。
  Future<List<String>> getAllComicIds() async {
    final rows = await select(comics).get();
    return rows.map((r) => r.comicId).toList();
  }

  Future<DbComic?> findById(String comicId) {
    return (select(
      comics,
    )..where((t) => t.comicId.equals(comicId))).getSingleOrNull();
  }

  Future<void> upsertMany(List<ComicsCompanion> companions) async {
    await batch((b) {
      b.insertAllOnConflictUpdate(comics, companions);
    });
  }

  Future<int> deleteByIds(List<String> comicIds) {
    if (comicIds.isEmpty) return Future.value(0);
    return (delete(comics)..where((t) => t.comicId.isIn(comicIds))).go();
  }

  Future<void> replaceComicTags(String comicId, List<String> tagNames) async {
    await transaction(() async {
      await (delete(comicTags)..where((t) => t.comicId.equals(comicId))).go();
      if (tagNames.isEmpty) return;
      final rows = tagNames
          .toSet()
          .map(
            (name) =>
                ComicTagsCompanion.insert(comicId: comicId, tagName: name),
          )
          .toList();
      await batch((b) => b.insertAll(comicTags, rows));
    });
  }

  Future<List<String>> getTagNamesForComic(String comicId) async {
    final rows = await (select(
      comicTags,
    )..where((t) => t.comicId.equals(comicId))).get();
    return rows.map((e) => e.tagName).toList();
  }

  Future<Map<String, List<String>>> getTagNamesForComics(
    Iterable<String> comicIds,
  ) async {
    final ids = comicIds.toList();
    if (ids.isEmpty) return {};
    final rows = await (select(
      comicTags,
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
    return (update(comics)..where((t) => t.comicId.equals(comicId))).write(
      ComicsCompanion(
        title: title ?? const Value.absent(),
        authorsJson: authors ?? const Value.absent(),
        contentRating: contentRating ?? const Value.absent(),
      ),
    );
  }
}

@DriftAccessor(tables: [SeriesTable, SeriesItems])
class SeriesDao extends DatabaseAccessor<AppDatabase> with _$SeriesDaoMixin {
  SeriesDao(super.db);

  Stream<List<DbSeries>> watchAllSeries() => select(seriesTable).watch();

  Future<List<DbSeries>> getAllSeries() => select(seriesTable).get();

  Future<DbSeries?> findByName(String name) {
    return (select(
      seriesTable,
    )..where((t) => t.name.equals(name))).getSingleOrNull();
  }

  Future<void> createSeries(SeriesTableCompanion companion) async {
    await into(seriesTable).insert(companion, mode: InsertMode.insertOrIgnore);
  }

  /// 依赖 [SeriesItems] 外键 `ON UPDATE CASCADE`，子表 `series_name` 随父表改名。
  Future<int> renameSeries({required String name, required String newName}) {
    return (update(seriesTable)..where((t) => t.name.equals(name))).write(
      SeriesTableCompanion(name: Value(newName)),
    );
  }

  Future<int> deleteSeries(String seriesName) {
    return (delete(seriesTable)..where((t) => t.name.equals(seriesName))).go();
  }

  Future<void> assignComicExclusive({
    required String comicId,
    required String targetSeriesName,
    required int sortOrder,
  }) async {
    await transaction(() async {
      await (delete(seriesItems)..where((t) => t.comicId.equals(comicId))).go();

      await into(seriesItems).insertOnConflictUpdate(
        SeriesItemsCompanion.insert(
          seriesName: targetSeriesName,
          comicId: comicId,
          sortOrder: sortOrder,
        ),
      );
    });
  }

  Future<int> removeComic(String comicId) {
    return (delete(seriesItems)..where((t) => t.comicId.equals(comicId))).go();
  }

  /// 批量移除系列归属。
  Future<int> removeComicsFromSeries(Iterable<String> comicIds) {
    final ids = comicIds.toList();
    if (ids.isEmpty) return Future.value(0);
    return (delete(seriesItems)..where((t) => t.comicId.isIn(ids))).go();
  }

  /// 删除 series_items 中指向不存在 comics 的脏关联。
  Future<int> removeOrphanSeriesItems() {
    return customUpdate(
      '''
      DELETE FROM series_items
      WHERE comic_id NOT IN (SELECT comic_id FROM comics);
      ''',
      updates: {seriesItems},
    );
  }

  Future<List<DbSeriesItem>> getItemsForSeries(String seriesName) {
    return (select(seriesItems)
          ..where((t) => t.seriesName.equals(seriesName))
          ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]))
        .get();
  }

  Future<List<DbSeriesItem>> getAllSeriesItemsOrdered() {
    return (select(seriesItems)..orderBy([
          (SeriesItems t) => OrderingTerm.asc(t.seriesName),
          (SeriesItems t) => OrderingTerm.asc(t.sortOrder),
        ]))
        .get();
  }

  /// 仅更新同系列内条目的 [SeriesItems.sortOrder]（不移动系列归属）。
  Future<int> updateSeriesItemSortOrder({
    required String seriesName,
    required String comicId,
    required int sortOrder,
  }) {
    return (update(seriesItems)..where(
          (SeriesItems t) =>
              t.seriesName.equals(seriesName) & t.comicId.equals(comicId),
        ))
        .write(SeriesItemsCompanion(sortOrder: Value(sortOrder)));
  }
}

@DriftAccessor(tables: [Tags, ComicTags])
class TagDao extends DatabaseAccessor<AppDatabase> with _$TagDaoMixin {
  TagDao(super.db);

  Future<List<DbTag>> listAll() => select(tags).get();

  Future<void> addTag(String name) async {
    await into(
      tags,
    ).insert(TagsCompanion.insert(name: name), mode: InsertMode.insertOrIgnore);
  }

  Future<int> deleteByNames(List<String> names) {
    if (names.isEmpty) return Future.value(0);
    return (delete(tags)..where((t) => t.name.isIn(names))).go();
  }

  Future<void> renameTag(String oldName, String newName) async {
    await transaction(() async {
      await into(tags).insert(
        TagsCompanion.insert(name: newName),
        mode: InsertMode.insertOrIgnore,
      );

      await (update(comicTags)..where((t) => t.tagName.equals(oldName))).write(
        ComicTagsCompanion(tagName: Value(newName)),
      );

      await (delete(tags)..where((t) => t.name.equals(oldName))).go();
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

@DriftAccessor(tables: [ComicReadingHistories])
class ReadingHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$ReadingHistoryDaoMixin {
  ReadingHistoryDao(super.db);

  Future<void> recordReading(ComicReadingHistoriesCompanion companion) async {
    await into(comicReadingHistories).insert(
      companion,
      onConflict: DoUpdate(
        (old) => ComicReadingHistoriesCompanion.custom(
          lastReadTime: Variable(companion.lastReadTime.value),
          title: Variable(companion.title.value),
          pageIndex: companion.pageIndex.present
              ? Variable(companion.pageIndex.value)
              : null,
        ),
        target: [comicReadingHistories.comicId],
      ),
    );
  }

  Future<ComicReadingHistoryRow?> getReadingHistoryByComicId(String comicId) {
    return (select(
      comicReadingHistories,
    )..where((t) => t.comicId.equals(comicId))).getSingleOrNull();
  }

  Stream<List<ComicReadingHistoryRow>> watchAllHistory() {
    return (select(
      comicReadingHistories,
    )..orderBy([(t) => OrderingTerm.desc(t.lastReadTime)])).watch();
  }

  Future<int> deleteByComicId(String comicId) {
    return (delete(
      comicReadingHistories,
    )..where((t) => t.comicId.equals(comicId))).go();
  }

  Future<int> deleteByComicIds(Iterable<String> comicIds) {
    final ids = comicIds.toList();
    if (ids.isEmpty) return Future.value(0);
    return (delete(
      comicReadingHistories,
    )..where((t) => t.comicId.isIn(ids))).go();
  }

  Future<int> clearAllHistory() {
    return delete(comicReadingHistories).go();
  }

  Future<void> clearExpiredHistory() async {
    final limitDate = DateTime.now().subtract(const Duration(days: 365));
    await (delete(
      comicReadingHistories,
    )..where((t) => t.lastReadTime.isSmallerThanValue(limitDate))).go();
  }
}

@DriftAccessor(tables: [SeriesReadingHistories])
class SeriesReadingHistoryDao extends DatabaseAccessor<AppDatabase>
    with _$SeriesReadingHistoryDaoMixin {
  SeriesReadingHistoryDao(super.db);

  Future<void> recordSeriesReading(
    SeriesReadingHistoriesCompanion companion,
  ) async {
    await into(seriesReadingHistories).insert(
      companion,
      onConflict: DoUpdate(
        (old) => SeriesReadingHistoriesCompanion.custom(
          lastReadTime: Variable(companion.lastReadTime.value),
          lastReadComicId: Variable(companion.lastReadComicId.value),
          pageIndex: companion.pageIndex.present
              ? Variable(companion.pageIndex.value)
              : null,
        ),
        target: [seriesReadingHistories.seriesName],
      ),
    );
  }

  Future<SeriesReadingHistoryRow?> getBySeriesName(String seriesName) {
    return (select(
      seriesReadingHistories,
    )..where((t) => t.seriesName.equals(seriesName))).getSingleOrNull();
  }

  Stream<List<SeriesReadingHistoryRow>> watchAllSeriesReading() {
    return (select(
      seriesReadingHistories,
    )..orderBy([(t) => OrderingTerm.desc(t.lastReadTime)])).watch();
  }

  Future<int> deleteBySeriesName(String seriesName) {
    return (delete(
      seriesReadingHistories,
    )..where((t) => t.seriesName.equals(seriesName))).go();
  }

  Future<int> deleteByLastReadComicIds(Iterable<String> comicIds) {
    final ids = comicIds.toList();
    if (ids.isEmpty) return Future.value(0);
    return (delete(
      seriesReadingHistories,
    )..where((t) => t.lastReadComicId.isIn(ids))).go();
  }

  Future<int> clearAllSeriesReading() {
    return delete(seriesReadingHistories).go();
  }

  Future<void> clearExpiredSeriesReading() async {
    final limitDate = DateTime.now().subtract(const Duration(days: 365));
    await (delete(
      seriesReadingHistories,
    )..where((t) => t.lastReadTime.isSmallerThanValue(limitDate))).go();
  }
}
