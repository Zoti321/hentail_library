part of 'dao.dart';

@DriftAccessor(tables: [Comics, SeriesTable])
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
}
