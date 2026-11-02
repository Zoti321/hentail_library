/// 漫画元数据字段锁切换（与生产 [ComicMetaLocks] 字段一一对应）。
typedef Md3eComicMetadataLockChanged = void Function({
  bool? title,
  bool? description,
  bool? publishedAt,
  bool? contentRating,
  bool? authors,
  bool? tags,
  bool? languages,
  bool? parodies,
  bool? characters,
});

/// 系列元数据字段锁切换。
typedef Md3eSeriesMetadataLockChanged = void Function({
  bool? name,
  bool? serializationStatus,
  bool? totalCount,
});
