import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:hentai_library/features/series/domain/value_objects/serialization_status.dart';
import 'package:hentai_library/features/series/domain/value_objects/series_meta_locks.dart';

part 'series_metadata.freezed.dart';

@freezed
abstract class SeriesMetadata with _$SeriesMetadata {
  const factory SeriesMetadata({
    required String name,
    @Default(SerializationStatus.unknown)
    SerializationStatus serializationStatus,
    int? totalCount,
    @Default(SeriesMetaLocks.unlocked) SeriesMetaLocks locks,
  }) = _SeriesMetadata;
}
