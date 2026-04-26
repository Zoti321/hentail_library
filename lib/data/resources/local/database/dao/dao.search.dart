part of 'dao.dart';

@DriftAccessor(tables: [Comics, SeriesTable, ComicTags, SeriesItems])
class SearchDao extends DatabaseAccessor<AppDatabase> with _$SearchDaoMixin {
  SearchDao(super.db);

  Future<List<String>> searchComicIdsByKeyword(String keyword) async {
    final String q = keyword.trim().toLowerCase();
    if (q.isEmpty) {
      return <String>[];
    }
    final Expression<String> loweredTitle = comics.title.lower();
    final query = selectOnly(comics)
      ..addColumns(<Expression<Object>>[comics.comicId])
      ..where(loweredTitle.like('%$q%'));
    final List<TypedResult> rows = await query.get();
    return rows
        .map((TypedResult row) => row.read<String>(comics.comicId))
        .whereType<String>()
        .toList();
  }

  Future<List<String>> searchSeriesNamesByKeyword(String keyword) async {
    final String q = keyword.trim().toLowerCase();
    if (q.isEmpty) {
      return <String>[];
    }
    final Expression<String> loweredName = seriesTable.name.lower();
    final query = selectOnly(seriesTable)
      ..addColumns(<Expression<Object>>[seriesTable.name])
      ..where(loweredName.like('%$q%'));
    final List<TypedResult> rows = await query.get();
    return rows
        .map((TypedResult row) => row.read<String>(seriesTable.name))
        .whereType<String>()
        .toList();
  }

  Future<List<String>> searchComicIdsByTagExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  }) async {
    final Set<String> includes = _normalizeTagSet(mustInclude);
    final Set<String> optional = _normalizeTagSet(optionalOr);
    final Set<String> excludes = _normalizeTagSet(mustExclude);
    if (includes.isEmpty && optional.isEmpty && excludes.isEmpty) {
      return <String>[];
    }
    final StringBuffer sql = StringBuffer(
      'SELECT c.comic_id FROM comics c WHERE 1=1',
    );
    final List<Variable<Object>> variables = <Variable<Object>>[];
    for (final String tag in includes) {
      sql.write(
        ' AND EXISTS (SELECT 1 FROM comic_tags ct WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) = ?)',
      );
      variables.add(Variable<Object>(tag));
    }
    if (optional.isNotEmpty) {
      final List<String> placeholders = List<String>.filled(
        optional.length,
        '?',
      );
      sql.write(
        ' AND EXISTS (SELECT 1 FROM comic_tags ct WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN (${placeholders.join(',')}))',
      );
      for (final String tag in optional) {
        variables.add(Variable<Object>(tag));
      }
    }
    if (excludes.isNotEmpty) {
      final List<String> placeholders = List<String>.filled(
        excludes.length,
        '?',
      );
      sql.write(
        ' AND NOT EXISTS (SELECT 1 FROM comic_tags ct WHERE ct.comic_id = c.comic_id AND lower(ct.tag_name) IN (${placeholders.join(',')}))',
      );
      for (final String tag in excludes) {
        variables.add(Variable<Object>(tag));
      }
    }
    final List<QueryRow> rows = await customSelect(
      sql.toString(),
      variables: variables,
      readsFrom: <TableInfo<Table, Object>>{comics, comicTags},
    ).get();
    return rows
        .map((QueryRow row) => row.read<String>('comic_id'))
        .whereType<String>()
        .toList();
  }

  Future<List<String>> searchSeriesNamesByTagExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  }) async {
    final List<String> comicIds = await searchComicIdsByTagExpression(
      mustInclude: mustInclude,
      optionalOr: optionalOr,
      mustExclude: mustExclude,
    );
    if (comicIds.isEmpty) {
      return <String>[];
    }
    final query = selectOnly(seriesItems, distinct: true)
      ..addColumns(<Expression<Object>>[seriesItems.seriesName])
      ..where(seriesItems.comicId.isIn(comicIds));
    final List<TypedResult> rows = await query.get();
    return rows
        .map((TypedResult row) => row.read<String>(seriesItems.seriesName))
        .whereType<String>()
        .toList();
  }

  Set<String> _normalizeTagSet(Set<String> source) {
    return source
        .map((String value) => value.trim().toLowerCase())
        .where((String value) => value.isNotEmpty)
        .toSet();
  }
}
