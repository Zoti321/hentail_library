import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/models/value_objects/series_comics_metadata.dart';

/// Series 仓储：文件夹 sync 自动生成；用户可编辑连载状态与计划总卷数。
abstract class SeriesRepository {
  Stream<List<Series>> watchAll();

  Future<List<Series>> getAll();

  Future<int> countAll();

  Future<PagedResult<Series>> fetchPage({
    required PageRequest request,
    required LibrarySeriesFilter filter,
    required LibrarySeriesSortOption sortOption,
  });

  Future<Series?> findById(String seriesId);

  Future<PagedResult<Comic>> fetchComicsPage({
    required String seriesId,
    required PageRequest request,
  });

  Future<SeriesComicsMetadata> fetchComicsMetadata(String seriesId);

  Future<void> updateUserMeta({
    required String seriesId,
    String? name,
    SerializationStatus? serializationStatus,
    int? totalCount,
    bool clearTotalCount = false,
  });

  /// 保留底层 API，供后续开放手动排序。
  Future<void> setSeriesItemsOrder(
    String seriesId,
    List<SeriesItem> orderedItems,
  );

  Future<List<Series>> searchByKeyword(String keyword);

  Future<List<Series>> searchByMetadataExpression({
    required Set<String> mustInclude,
    required Set<String> optionalOr,
    required Set<String> mustExclude,
  });
}
