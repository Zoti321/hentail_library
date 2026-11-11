import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/series/domain/series_item.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_meta_locks.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';

part 'series.freezed.dart';

/// 系列聚合：由 Library sync 根据文件夹结构自动生成。
///
/// 真源 @ `features/series/domain/`（ADR-0042）；跨模块只交换窄投影或 Port 事实。
@freezed
abstract class Series with _$Series {
  factory Series({
    required String id,
    required String name,
    required String folderPath,
    @Default(SerializationStatus.unknown)
    SerializationStatus serializationStatus,
    int? totalCount,
    @Default(SeriesMetaLocks.unlocked) SeriesMetaLocks locks,
    @Default(<SeriesItem>[]) List<SeriesItem> items,
  }) = _Series;
}
