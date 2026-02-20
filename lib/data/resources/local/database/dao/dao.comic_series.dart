part of 'dao.dart';

@DriftAccessor(tables: [Comics, ComicTags, Authors, ComicAuthors])
class ComicDao extends DatabaseAccessor<AppDatabase> with _$ComicDaoMixin {
  ComicDao(super.db);

  Stream<List<DbComic>> watchAllComics() => select(comics).watch();

  Future<List<DbComic>> getAllComics() => select(comics).get();

  /// 仅 comicId 列，用于大库 diff 等场景（不加载 tags）。
  Future<List<String>> getAllComicIds() async {
    final rows = await select(comics).get();
    return rows.map((r) => r.comicId).toList();
  }

  /// 仅获取 comicId 与 path，用于轻量批处理场景。
  Future<List<({String comicId, String path})>> getAllComicIdAndPaths() async {
    final query = selectOnly(comics)..addColumns([comics.comicId, comics.path]);
    final rows = await query.get();
    final List<({String comicId, String path})> result =
        <({String comicId, String path})>[];
    for (final TypedResult row in rows) {
      final String? comicId = row.read(comics.comicId);
      final String? path = row.read(comics.path);
      if (comicId == null || path == null) {
        continue;
      }
      result.add((comicId: comicId, path: path));
    }
    return result;
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

  Future<void> replaceComicAuthors(
    String comicId,
    List<String> authorNames,
  ) async {
    await transaction(() async {
      await (delete(comicAuthors)..where((t) => t.comicId.equals(comicId)))
          .go();
      final uniqueNames = authorNames.toSet().toList();
      if (uniqueNames.isEmpty) return;
      await batch((b) {
        for (final String name in uniqueNames) {
          b.insert(
            authors,
            AuthorsCompanion.insert(name: name),
            mode: InsertMode.insertOrIgnore,
          );
        }
      });
      final rows = uniqueNames
          .map(
            (name) => ComicAuthorsCompanion.insert(
              comicId: comicId,
              authorName: name,
            ),
          )
          .toList();
      await batch((b) => b.insertAll(comicAuthors, rows));
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

  Future<List<String>> getAuthorNamesForComic(String comicId) async {
    final rows = await (select(
      comicAuthors,
    )..where((t) => t.comicId.equals(comicId))).get();
    return rows.map((e) => e.authorName).toList();
  }

  Future<Map<String, List<String>>> getAuthorNamesForComics(
    Iterable<String> comicIds,
  ) async {
    final ids = comicIds.toList();
    if (ids.isEmpty) return {};
    final rows = await (select(
      comicAuthors,
    )..where((t) => t.comicId.isIn(ids))).get();
    final map = <String, List<String>>{};
    for (final r in rows) {
      (map[r.comicId] ??= <String>[]).add(r.authorName);
    }
    return map;
  }

  Future<int> updateUserMeta(
    String comicId, {
    Value<String>? title,
    Value<ContentRating>? contentRating,
  }) {
    return (update(comics)..where((t) => t.comicId.equals(comicId))).write(
      ComicsCompanion(
        title: title ?? const Value.absent(),
        contentRating: contentRating ?? const Value.absent(),
      ),
    );
  }

  /// 批量更新指定漫画的内容分级。
  Future<int> batchUpdateContentRatingByComicIds(
    Iterable<String> comicIds,
    ContentRating contentRating,
  ) {
    final List<String> ids = comicIds.toList();
    if (ids.isEmpty) {
      return Future<int>.value(0);
    }
    return (update(
      comics,
    )..where((Comics t) => t.comicId.isIn(ids))).write(
      ComicsCompanion(contentRating: Value<ContentRating>(contentRating)),
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
    final List<String> ids = comicIds.toList();
    if (ids.isEmpty) return Future<int>.value(0);
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
