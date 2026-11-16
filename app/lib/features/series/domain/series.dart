import 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/series/domain/series_item.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_meta_locks.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_folder_info.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_metadata.dart';

part 'series.freezed.dart';

const int maxSeriesTotalCount = 2147483647;

/// 系列聚合：由 Library sync 根据文件夹结构自动生成。
///
/// 真源 @ `features/series/domain/`（ADR-0042）；跨模块只交换窄投影或 Port 事实。
@freezed
abstract class Series with _$Series {
  factory Series({
    required String id,
    required SeriesFolderInfo folderInfo,
    required SeriesMetadata metadata,
    @Default(<SeriesItem>[]) List<SeriesItem> items,
  }) = _Series;

  const Series._();

  String get folderPath => folderInfo.folderPath;
  String get name => metadata.name;
  SerializationStatus get serializationStatus => metadata.serializationStatus;
  int? get totalCount => metadata.totalCount;
  SeriesMetaLocks get locks => metadata.locks;
}
