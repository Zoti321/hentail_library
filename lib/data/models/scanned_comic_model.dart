import 'package:freezed_annotation/freezed_annotation.dart';

part 'scanned_comic_model.freezed.dart';

/// 与数据库无关的扫描结果：一次路径扫描对应一本漫画 + 一个章节。
/// 由 [ComicScannerService] 生成；持久化由 v2 资源解析与映射链路完成，不经过旧版同步服务。
@freezed
abstract class ScannedComicModel with _$ScannedComicModel {
  const factory ScannedComicModel({
    required String comicId,
    required String title,
    String? description,
    String? coverUrl,
    DateTime? firstPublishedAt,
    DateTime? lastUpdatedAt,
    required String chapterId,
    String? chapterTitle,
    String? chapterCoverUrl,
    int? pageCount,
    required String imageDir,
    String? sourcePath,
    @Default(1) int chapterNumber,
  }) = _ScannedComicModel;

  const ScannedComicModel._();
}
