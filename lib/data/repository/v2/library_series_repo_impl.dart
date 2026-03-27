import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart'
    as db;
import 'package:hentai_library/domain/entity/v2/library_series.dart' as entity;
import 'package:hentai_library/domain/entity/v2/series_item.dart' as entity;
import 'package:hentai_library/domain/repository/v2/library_series_repo.dart';

class LibrarySeriesRepositoryImpl implements LibrarySeriesRepository {
  final LibrarySeriesDao _dao;

  LibrarySeriesRepositoryImpl(this._dao);

  @override
  Stream<List<entity.LibrarySeries>> watchAll() {
    return _dao.watchAllSeries().asyncMap((rows) async {
      // 目前只映射 series 基本信息；items 由 findById/getAll 单独查询。
      return rows
          .map(
            (r) => entity.LibrarySeries(
              seriesId: r.seriesId,
              name: r.name,
              items: const [],
            ),
          )
          .toList();
    });
  }

  @override
  Future<List<entity.LibrarySeries>> getAll() async {
    final seriesRows = await _dao.getAllSeries();
    final result = <entity.LibrarySeries>[];
    for (final s in seriesRows) {
      final items = await _dao.getItemsForSeries(s.seriesId);
      result.add(
        entity.LibrarySeries(
          seriesId: s.seriesId,
          name: s.name,
          items: items
              .map(
                (i) => entity.SeriesItem(
                  comicId: i.comicId,
                  order: i.sortOrder,
                ),
              )
              .toList(),
        ),
      );
    }
    return result;
  }

  @override
  Future<entity.LibrarySeries?> findById(String seriesId) async {
    final row = await _dao.findById(seriesId);
    if (row == null) return null;
    final items = await _dao.getItemsForSeries(seriesId);
    return entity.LibrarySeries(
      seriesId: row.seriesId,
      name: row.name,
      items: items
          .map(
            (i) => entity.SeriesItem(
              comicId: i.comicId,
              order: i.sortOrder,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<void> create(String name) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _dao.createSeries(
      db.LibrarySeriesCompanion.insert(
        seriesId: id,
        name: name,
      ),
    );
  }

  @override
  Future<void> rename(String seriesId, String name) async {
    await _dao.renameSeries(seriesId, name);
  }

  @override
  Future<void> delete(String seriesId) async {
    await _dao.deleteSeries(seriesId);
  }

  @override
  Future<void> assignComicExclusive({
    required String comicId,
    required String targetSeriesId,
    required int order,
  }) async {
    await _dao.assignComicExclusive(
      comicId: comicId,
      targetSeriesId: targetSeriesId,
      sortOrder: order,
    );
  }

  @override
  Future<void> removeComic(String comicId) async {
    await _dao.removeComic(comicId);
  }
}

