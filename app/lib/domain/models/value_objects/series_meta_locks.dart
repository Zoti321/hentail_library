import 'package:flutter/foundation.dart';

/// Series 元数据字段锁（Komga 式）；默认全部未锁。
@immutable
class SeriesMetaLocks {
  const SeriesMetaLocks({
    this.name = false,
    this.serializationStatus = false,
    this.totalCount = false,
  });

  static const SeriesMetaLocks unlocked = SeriesMetaLocks();

  final bool name;
  final bool serializationStatus;
  final bool totalCount;

  SeriesMetaLocks copyWith({
    bool? name,
    bool? serializationStatus,
    bool? totalCount,
  }) {
    return SeriesMetaLocks(
      name: name ?? this.name,
      serializationStatus: serializationStatus ?? this.serializationStatus,
      totalCount: totalCount ?? this.totalCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SeriesMetaLocks &&
          name == other.name &&
          serializationStatus == other.serializationStatus &&
          totalCount == other.totalCount;

  @override
  int get hashCode => Object.hash(name, serializationStatus, totalCount);
}
