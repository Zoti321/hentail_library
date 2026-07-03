import 'package:hentai_library/data/adapters/frb_call_guard.dart';
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
    return guardFrbStream(
      () => rust_series.watchAllSeriesFrb().map(
        (List<rust_series.SeriesDto> rows) =>
            rows.map(mapRustSeries).toList(),
      ),
      fallbackMessage: '监听系列列表失败',
    );
  }

  @override
  Future<List<Series>> getAll() async {
    return guardFrbSync(
      () => rust_series.getAllSeriesFrb().map(mapRustSeries).toList(),
      fallbackMessage: '读取系列列表失败',
    );
  }

  @override
  Future<PagedResult<Series>> fetchPage(PageRequest request) async {
    final rust_series.PagedSeriesResultDto page = guardFrbSync(
      () => rust_series.fetchSeriesPageFrb(
        request: rust.PageRequestDto(
          page: request.page,
          pageSize: request.pageSize,
        ),
      ),
      fallbackMessage: '读取系列分页失败',
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
    final rust_series.SeriesDto? dto = guardFrbSync(
      () => rust_series.findSeriesByNameFrb(name: name),
      fallbackMessage: '读取系列失败',
    );
    return dto == null ? null : mapRustSeries(dto);
  }

  @override
  Future<void> create(String name) async {
    guardFrbSync(
      () => rust_series.createSeriesFrb(name: name),
      fallbackMessage: '创建系列失败',
    );
  }

  @override
  Future<void> rename({required String name, required String newName}) async {
    guardFrbSync(
      () => rust_series.renameSeriesFrb(name: name, newName: newName),
      fallbackMessage: '重命名系列失败',
    );
  }

  @override
  Future<void> delete(String name) async {
    guardFrbSync(
      () => rust_series.deleteSeriesFrb(name: name),
      fallbackMessage: '删除系列失败',
    );
  }

  @override
  Future<void> assignComicExclusive({
    required String comicId,
    required String targetSeriesName,
    required int order,
  }) async {
    guardFrbSync(
      () => rust_series.assignComicExclusiveFrb(
        comicId: comicId,
        targetSeriesName: targetSeriesName,
        sortOrder: order,
      ),
      fallbackMessage: '分配漫画到系列失败',
    );
  }

  @override
  Future<void> removeComic(String comicId) async {
    guardFrbSync(
      () => rust_series.removeComicFromSeriesFrb(comicId: comicId),
      fallbackMessage: '从系列移除漫画失败',
    );
  }

  @override
  Future<void> removeComicsFromSeries(Iterable<String> comicIds) async {
    guardFrbSync(
      () => rust_series.removeComicsFromSeriesFrb(comicIds: comicIds.toList()),
      fallbackMessage: '批量从系列移除漫画失败',
    );
  }

  @override
  Future<void> removeOrphanSeriesItems() async {
    guardFrbSync(
      rust_series.removeOrphanSeriesItemsFrb,
      fallbackMessage: '清理孤立系列项失败',
    );
  }

  @override
  Future<void> setSeriesItemsOrder(
    String seriesName,
    List<SeriesItem> orderedItems,
  ) async {
    guardFrbSync(
      () => rust_series.setSeriesItemsOrderFrb(
        seriesName: seriesName,
        orderedComicIds: orderedItems.map((SeriesItem i) => i.comicId).toList(),
      ),
      fallbackMessage: '更新系列排序失败',
    );
  }

  @override
  Future<List<Series>> searchByKeyword(String keyword) async {
    return guardFrbSync(
      () => rust_series
          .searchSeriesByKeywordFrb(keyword: keyword)
          .map(mapRustSeries)
          .toList(),
      fallbackMessage: '搜索系列失败',
    );
  }

  @override
  Future<List<Series>> searchByTagExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  }) async {
    return guardFrbSync(
      () => rust_series
          .searchSeriesByTagExpressionFrb(
            mustInclude: mustInclude.toList(),
            optionalOr: optionalOr.toList(),
            mustExclude: mustExclude.toList(),
          )
          .map(mapRustSeries)
          .toList(),
      fallbackMessage: '按标签搜索系列失败',
    );
  }

  @override
  Future<InferSeriesFromComicTitlesResult> inferFromUnassignedComics() async {
    final rust_series.InferSeriesResultDto result = guardFrbSync(
      rust_series.inferSeriesFrb,
      fallbackMessage: '推断系列失败',
    );
    return InferSeriesFromComicTitlesResult(
      groupsApplied: result.groupsApplied,
      comicsAssigned: result.comicsAssigned,
      newSeriesCreated: result.newSeriesCreated,
    );
  }
}
