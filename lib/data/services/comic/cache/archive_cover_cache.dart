import 'dart:typed_data';

import 'package:hentai_library/core/util/path_normalizer.dart';

/// 与 Isolate 解码侧一致的源路径规范化（用于 meta 比对）。
String normalizeArchiveCoverSourcePath(String raw) {
  return const PathNormalizer().normalizeForKey(raw);
}

/// 归档漫画封面磁盘缓存（仅列表/卡片 [comicCoverDisplay]，不用于阅读正文）。
abstract class ArchiveCoverCache {
  /// 若 meta 与源文件 stat 一致且缓存图存在，返回缓存文件绝对路径，否则返回 null。
  Future<String?> tryReadValidPath({
    required String comicId,
    required String sourcePathNormalized,
  });

  /// 写入封面字节与 meta；成功返回缓存图片绝对路径，失败返回 null。
  Future<String?> write({
    required String comicId,
    required String sourcePathNormalized,
    required Uint8List bytes,
    required String fileExtension,
  });

  /// 删除该漫画对应的 meta 与封面图文件。
  Future<void> clearForComic(String comicId);

  /// 清空整个封面缓存子目录内本功能创建的文件。
  Future<void> clearAll();

  /// 当前封面缓存目录内文件总字节数（含 meta）。
  Future<int> totalBytesInCache();
}
