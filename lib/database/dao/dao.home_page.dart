part of 'dao.dart';

@DriftAccessor(
  tables: [
    Comics,
    Authors,
    Tags,
    SeriesTable,
    SeriesItems,
    ComicReadingHistories,
    SeriesReadingHistories,
  ],
)
class HomePageDao extends DatabaseAccessor<AppDatabase>
    with _$HomePageDaoMixin {
  HomePageDao(super.db);
  static const String _kContentRatingR18 = 'r18';
  static const String _kSqlHomePageCounts = '''
    SELECT
      (SELECT COUNT(*) FROM comics) AS c_comic,
      (SELECT COUNT(*) FROM tags) AS c_tag,
      (SELECT COUNT(*) FROM series) AS c_series,
      (SELECT COUNT(*) FROM comic_reading_histories) AS c_comic_h,
      (SELECT COUNT(*) FROM series_reading_histories) AS c_series_h
  ''';
  static const String _kSqlHomePageCountsHealthy = '''
    SELECT
      (SELECT COUNT(*) FROM comics WHERE content_rating != ?) AS c_comic,
      (SELECT COUNT(*) FROM tags) AS c_tag,
      (
        SELECT COUNT(*)
        FROM series s
        WHERE EXISTS (SELECT 1 FROM series_items si0 WHERE si0.series_name = s.name)
        AND NOT EXISTS (
          SELECT 1
          FROM series_items si1
          INNER JOIN comics c1 ON c1.comic_id = si1.comic_id
          WHERE si1.series_name = s.name AND c1.content_rating = ?
        )
      ) AS c_series,
      (
        SELECT COUNT(*)
        FROM comic_reading_histories h
        INNER JOIN comics c ON c.comic_id = h.comic_id
        WHERE c.content_rating != ?
      ) AS c_comic_h,
      (
        SELECT COUNT(*)
        FROM series_reading_histories srh
        WHERE NOT EXISTS (
          SELECT 1
          FROM series_items si2
          INNER JOIN comics c2 ON c2.comic_id = si2.comic_id
          WHERE si2.series_name = srh.series_name AND c2.content_rating = ?
        )
      ) AS c_series_h
  ''';
  static const String _kSqlRecentTop5Reading = '''
    SELECT
      kind,
      last_read_time,
      comic_id,
      title,
      series_name,
      last_read_comic_id,
      page_index
    FROM (
      SELECT
        'c' AS kind,
        h.last_read_time,
        h.comic_id,
        h.title,
        NULL AS series_name,
        NULL AS last_read_comic_id,
        h.page_index
      FROM comic_reading_histories h
      UNION ALL
      SELECT
        's' AS kind,
        srh.last_read_time,
        NULL AS comic_id,
        NULL AS title,
        srh.series_name,
        srh.last_read_comic_id,
        srh.page_index
      FROM series_reading_histories srh
    ) AS merged
    ORDER BY last_read_time DESC
    LIMIT 5
  ''';
  static const String _kSqlRecentTop5ReadingWithoutR18 = '''
    SELECT
      kind,
      last_read_time,
      comic_id,
      title,
      series_name,
      last_read_comic_id,
      page_index
    FROM (
      SELECT
        'c' AS kind,
        h.last_read_time,
        h.comic_id,
        h.title,
        NULL AS series_name,
        NULL AS last_read_comic_id,
        h.page_index
      FROM comic_reading_histories h
      INNER JOIN comics c ON c.comic_id = h.comic_id
      WHERE c.content_rating != ?
      UNION ALL
      SELECT
        's' AS kind,
        srh.last_read_time,
        NULL AS comic_id,
        NULL AS title,
        srh.series_name,
        srh.last_read_comic_id,
        srh.page_index
      FROM series_reading_histories srh
      WHERE NOT EXISTS (
        SELECT 1
        FROM series_items si
        INNER JOIN comics c ON c.comic_id = si.comic_id
        WHERE si.series_name = srh.series_name AND c.content_rating = ?
      )
    ) AS merged
    ORDER BY last_read_time DESC
    LIMIT 5
  ''';
  static const String _kSqlWatchTrigger = 'SELECT 1 AS _h';

  List<Variable<Object>> _buildR18Variables(int count) {
    return List<Variable<Object>>.generate(
      count,
      (_) => Variable<String>(_kContentRatingR18),
    );
  }

  HomePageCounts _mapCountsRow(QueryRow row) {
    return HomePageCounts(
      comicCount: row.read<int>('c_comic'),
      tagCount: row.read<int>('c_tag'),
      seriesCount: row.read<int>('c_series'),
      readingRecordCount:
          row.read<int>('c_comic_h') + row.read<int>('c_series_h'),
    );
  }

  HomeContinueReadingEntry _mapContinueReadingRow(QueryRow row) {
    final String kind = row.read<String>('kind');
    final DateTime lastReadTime = row.read<DateTime>('last_read_time');
    if (kind == 'c') {
      return HomeContinueReadingEntry.comic(
        comicId: row.read<String>('comic_id'),
        title: row.read<String>('title'),
        lastReadTime: lastReadTime,
        pageIndex: row.read<int?>('page_index'),
      );
    }
    return HomeContinueReadingEntry.series(
      seriesName: row.read<String>('series_name'),
      lastReadComicId: row.read<String>('last_read_comic_id'),
      lastReadTime: lastReadTime,
      pageIndex: row.read<int?>('page_index'),
    );
  }

  String _resolveTop5Sql({required bool excludeR18}) {
    if (excludeR18) {
      return _kSqlRecentTop5ReadingWithoutR18;
    }
    return _kSqlRecentTop5Reading;
  }

  List<Variable<Object>> _resolveTop5Variables({required bool excludeR18}) {
    if (excludeR18) {
      return _buildR18Variables(2);
    }
    return const <Variable<Object>>[];
  }

  Future<List<HomeContinueReadingEntry>> _loadRecentTop5Reading({
    required bool excludeR18,
  }) async {
    final List<QueryRow> rows = await customSelect(
      _resolveTop5Sql(excludeR18: excludeR18),
      variables: _resolveTop5Variables(excludeR18: excludeR18),
      readsFrom: {
        comics,
        seriesItems,
        comicReadingHistories,
        seriesReadingHistories,
      },
    ).get();
    return rows.map(_mapContinueReadingRow).toList();
  }

  Stream<List<HomeContinueReadingEntry>> _watchRecentTop5Reading({
    required bool excludeR18,
  }) {
    final Set<TableInfo<Table, Object>> readsFrom =
        excludeR18
        ? <TableInfo<Table, Object>>{
            comics,
            seriesItems,
            comicReadingHistories,
            seriesReadingHistories,
          }
        : <TableInfo<Table, Object>>{
            comicReadingHistories,
            seriesReadingHistories,
          };
    return customSelect(
      _kSqlWatchTrigger,
      readsFrom: readsFrom,
    ).watch().asyncMap(
      (_) => _loadRecentTop5Reading(excludeR18: excludeR18),
    );
  }

  Map<String, int> _mapSeriesComicOrder(Iterable<DbSeriesItem> rows) {
    final Map<String, int> map = <String, int>{};
    for (final DbSeriesItem row in rows) {
      map['${row.seriesName}|${row.comicId}'] = row.sortOrder;
    }
    return map;
  }

  Future<Map<String, int>> loadHomeSeriesComicOrderMap() async {
    final List<DbSeriesItem> rows = await select(seriesItems).get();
    return _mapSeriesComicOrder(rows);
  }

  Stream<Map<String, int>> watchHomeSeriesComicOrderMap() {
    return select(
      seriesItems,
    ).watch().map((List<DbSeriesItem> rows) => _mapSeriesComicOrder(rows));
  }

  Future<HomePageCounts> loadHomePageCounts() async {
    final query = customSelect(
      _kSqlHomePageCounts,
      readsFrom: {
        comics,
        tags,
        seriesTable,
        comicReadingHistories,
        seriesReadingHistories,
      },
    );
    final QueryRow row = await query.getSingle();
    return _mapCountsRow(row);
  }

  Stream<HomePageCounts> watchHomePageCounts() {
    return customSelect(
      _kSqlWatchTrigger,
      readsFrom: {
        comics,
        tags,
        seriesTable,
        comicReadingHistories,
        seriesReadingHistories,
      },
    ).watch().asyncMap((_) => loadHomePageCounts());
  }

  Future<HomePageCounts> loadHomePageCountsHealthy() async {
    final query = customSelect(
      _kSqlHomePageCountsHealthy,
      variables: _buildR18Variables(4),
      readsFrom: {
        comics,
        tags,
        seriesTable,
        seriesItems,
        comicReadingHistories,
        seriesReadingHistories,
      },
    );
    final QueryRow row = await query.getSingle();
    return _mapCountsRow(row);
  }

  Stream<HomePageCounts> watchHomePageCountsHealthy() {
    return customSelect(
      _kSqlWatchTrigger,
      readsFrom: {
        comics,
        tags,
        seriesTable,
        seriesItems,
        comicReadingHistories,
        seriesReadingHistories,
      },
    ).watch().asyncMap((_) => loadHomePageCountsHealthy());
  }

  Stream<List<HomeContinueReadingEntry>> watchContinueReadingTop5() {
    return _watchRecentTop5Reading(excludeR18: false);
  }

  Stream<List<HomeContinueReadingEntry>> watchContinueReadingTop5Healthy() {
    return _watchRecentTop5Reading(excludeR18: true);
  }
}
