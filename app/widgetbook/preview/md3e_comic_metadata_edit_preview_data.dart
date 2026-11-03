import 'package:hentai_library/shared/domain/models/value_objects/comic_meta_locks.dart';

/// Widgetbook / Lab 漫画元数据编辑 preview 样例。
abstract final class Md3eComicMetadataEditPreviewData {
  /// 与生产演示相近的部分字段锁（KV 列表初始态）。
  static const ComicMetaLocks sampleLocks = ComicMetaLocks(
    title: true,
    tags: true,
  );
}
