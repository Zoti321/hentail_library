part of 'dao.dart';

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

  Future<int> countAllHistory() async {
    final QueryRow row = await customSelect(
      'SELECT COUNT(*) AS c FROM comic_reading_histories',
      readsFrom: <TableInfo<Table, Object>>{comicReadingHistories},
    ).getSingle();
    return row.read<int>('c')!;
  }

  Future<List<ComicReadingHistoryRow>> fetchHistoryPage({
    required int limit,
    required int offset,
  }) {
    return (select(comicReadingHistories)
          ..orderBy(<OrderingTerm Function(ComicReadingHistories t)>[
            (ComicReadingHistories t) => OrderingTerm.desc(t.lastReadTime),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<int> deleteByComicId(String comicId) {
    return (delete(
      comicReadingHistories,
    )..where((t) => t.comicId.equals(comicId))).go();
  }

  Future<int> deleteByComicIds(Iterable<String> comicIds) {
    final List<String> ids = comicIds.toList();
    if (ids.isEmpty) return Future<int>.value(0);
    return (delete(
      comicReadingHistories,
    )..where((t) => t.comicId.isIn(ids))).go();
  }

  Future<int> clearAllHistory() {
    return delete(comicReadingHistories).go();
  }

  Future<void> clearExpiredHistory() async {
    final DateTime limitDate = DateTime.now().subtract(
      const Duration(days: 365),
    );
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

  Future<int> countAllSeriesReading() async {
    final QueryRow row = await customSelect(
      'SELECT COUNT(*) AS c FROM series_reading_histories',
      readsFrom: <TableInfo<Table, Object>>{seriesReadingHistories},
    ).getSingle();
    return row.read<int>('c')!;
  }

  Future<List<SeriesReadingHistoryRow>> fetchSeriesReadingPage({
    required int limit,
    required int offset,
  }) {
    return (select(seriesReadingHistories)
          ..orderBy(<OrderingTerm Function(SeriesReadingHistories t)>[
            (SeriesReadingHistories t) => OrderingTerm.desc(t.lastReadTime),
          ])
          ..limit(limit, offset: offset))
        .get();
  }

  Future<int> deleteBySeriesName(String seriesName) {
    return (delete(
      seriesReadingHistories,
    )..where((t) => t.seriesName.equals(seriesName))).go();
  }

  Future<int> deleteByLastReadComicIds(Iterable<String> comicIds) {
    final List<String> ids = comicIds.toList();
    if (ids.isEmpty) return Future<int>.value(0);
    return (delete(
      seriesReadingHistories,
    )..where((t) => t.lastReadComicId.isIn(ids))).go();
  }

  Future<int> clearAllSeriesReading() {
    return delete(seriesReadingHistories).go();
  }

  Future<void> clearExpiredSeriesReading() async {
    final DateTime limitDate = DateTime.now().subtract(
      const Duration(days: 365),
    );
    await (delete(
      seriesReadingHistories,
    )..where((t) => t.lastReadTime.isSmallerThanValue(limitDate))).go();
  }
}
