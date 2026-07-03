import 'package:hentai_library/data/repositories/series_frb_mapper.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as rust;
import 'package:hentai_library/src/rust/api/series.dart' as rust_series;

class SeriesRepositoryImpl implements SeriesRepository {
  const SeriesRepositoryImpl();

  @override
  Stream<List<Series>> watchAll() {
    return rust_series.watchAllSeriesFrb().map(
      (List<rust_series.SeriesDto> rows) => rows.map(mapRustSeries).toList(),
    );
  }

  @override
  Future<List<Series>> getAll() async {
    return rust_series.getAllSeriesFrb().map(mapRustSeries).toList();
  }

  @override
  Future<PagedResult<Series>> fetchPage(PageRequest request) async {
    final rust_series.PagedSeriesResultDto page = rust_series
        .fetchSeriesPageFrb(
          request: rust.PageRequestDto(
            page: request.page,
            pageSize: request.pageSize,
          ),
        );
    return PagedResult<Series>(
      items: page.items.map(mapRustSeries).toList(),
      totalCount: page.totalCount.toInt(),
      page: page.page,
      pageSize: page.pageSize,
    );
  }

  @override
  Future<Series?> findByName(String name) async {
    final rust_series.SeriesDto? dto = rust_series.findSeriesByNameFrb(
      name: name,
    );
    return dto == null ? null : mapRustSeries(dto);
  }

  @override
  Future<void> create(String name) async {
    rust_series.createSeriesFrb(name: name);
  }

  @override
  Future<void> rename({required String name, required String newName}) async {
    rust_series.renameSeriesFrb(name: name, newName: newName);
  }

  @override
  Future<void> delete(String name) async {
    rust_series.deleteSeriesFrb(name: name);
  }

  @override
  Future<void> assignComicExclusive({
    required String comicId,
    required String targetSeriesName,
    required int order,
  }) async {
    rust_series.assignComicExclusiveFrb(
      comicId: comicId,
      targetSeriesName: targetSeriesName,
      sortOrder: order,
    );
  }

  @override
  Future<void> removeComic(String comicId) async {
    rust_series.removeComicFromSeriesFrb(comicId: comicId);
  }

  @override
  Future<void> removeComicsFromSeries(Iterable<String> comicIds) async {
    rust_series.removeComicsFromSeriesFrb(comicIds: comicIds.toList());
  }

  @override
  Future<void> removeOrphanSeriesItems() async {
    rust_series.removeOrphanSeriesItemsFrb();
  }

  @override
  Future<void> setSeriesItemsOrder(
    String seriesName,
    List<SeriesItem> orderedItems,
  ) async {
    rust_series.setSeriesItemsOrderFrb(
      seriesName: seriesName,
      orderedComicIds: orderedItems.map((SeriesItem i) => i.comicId).toList(),
    );
  }

  @override
  Future<List<Series>> searchByKeyword(String keyword) async {
    return rust_series
        .searchSeriesByKeywordFrb(keyword: keyword)
        .map(mapRustSeries)
        .toList();
  }

  @override
  Future<List<Series>> searchByTagExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  }) async {
    return rust_series
        .searchSeriesByTagExpressionFrb(
          mustInclude: mustInclude.toList(),
          optionalOr: optionalOr.toList(),
          mustExclude: mustExclude.toList(),
        )
        .map(mapRustSeries)
        .toList();
  }

  @override
  Future<InferSeriesFromComicTitlesResult> inferFromUnassignedComics() async {
    final rust_series.InferSeriesResultDto result = rust_series
        .inferSeriesFrb();
    return InferSeriesFromComicTitlesResult(
      groupsApplied: result.groupsApplied,
      comicsAssigned: result.comicsAssigned,
      newSeriesCreated: result.newSeriesCreated,
    );
  }
}
