import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/repositories/series_frb_mapper.dart';
import 'package:hentai_library/domain/library/library_comic_sort_option.dart';
import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/src/rust/api/series.dart' as rust_series;

class SeriesRepositoryImpl implements SeriesRepository {
  const SeriesRepositoryImpl();

  @override
  Stream<List<Series>> watchAll() {
    return guardFrbStream(
      () => rust_series.watchAllSeriesFrb().map(
        (List<rust_series.SeriesDto> rows) => rows.map(mapRustSeries).toList(),
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
  Future<PagedResult<Series>> fetchPage({
    required PageRequest request,
    required LibrarySeriesFilter filter,
    required LibraryComicSortOption sortOption,
  }) async {
    final rust_series.PagedSeriesResultDto page = guardFrbSync(
      () => rust_series.fetchSeriesPageFrb(
        request: mapSeriesPageRequest(request),
        filter: mapLibrarySeriesFilter(filter),
        sort: mapSeriesSortOption(sortOption),
      ),
      fallbackMessage: '读取系列分页失败',
    );
    return mapPagedSeriesResult(page);
  }

  @override
  Future<Series?> findById(String seriesId) async {
    final rust_series.SeriesDto? dto = guardFrbSync(
      () => rust_series.findSeriesByIdFrb(seriesId: seriesId),
      fallbackMessage: '读取系列失败',
    );
    return dto == null ? null : mapRustSeries(dto);
  }

  @override
  Future<void> updateUserMeta({
    required String seriesId,
    SerializationStatus? serializationStatus,
    int? totalCount,
    bool clearTotalCount = false,
  }) async {
    guardFrbSync(
      () => rust_series.updateSeriesUserMetaFrb(
        seriesId: seriesId,
        meta: mapUpdateSeriesUserMeta(
          serializationStatus: serializationStatus,
          totalCount: totalCount,
          clearTotalCount: clearTotalCount,
        ),
      ),
      fallbackMessage: '更新系列元数据失败',
    );
  }

  @override
  Future<void> setSeriesItemsOrder(
    String seriesId,
    List<SeriesItem> orderedItems,
  ) async {
    guardFrbSync(
      () => rust_series.setSeriesItemsOrderFrb(
        seriesId: seriesId,
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
}
