import 'package:hentai_library/domain/entity/comic/library_series.dart';

/// v2 Series 仓储：系列独立聚合，维护漫画归属与顺序。
abstract class LibrarySeriesRepository {
  Stream<List<LibrarySeries>> watchAll();

  Future<List<LibrarySeries>> getAll();

  Future<LibrarySeries?> findById(String seriesId);

  Future<void> create(String name);

  Future<void> rename(String seriesId, String name);

  Future<void> delete(String seriesId);

  /// 排他归属：保证同一 comicId 只能属于一个系列。
  Future<void> assignComicExclusive({
    required String comicId,
    required String targetSeriesId,
    required int order,
  });

  Future<void> removeComic(String comicId);

  /// 批量移除系列中的漫画归属（无 FK 指向 comics，清空库时需单独清理）。
  Future<void> removeComicsFromSeries(Iterable<String> comicIds);
}
