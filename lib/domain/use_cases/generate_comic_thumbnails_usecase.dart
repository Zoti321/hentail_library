import 'package:hentai_library/data/services/comic/thumbnail/comic_thumbnail_service.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';

typedef GenerateComicThumbnailsResult = ({int failedCount});

typedef GenerateComicThumbnailsProgress = ({
  int done,
  int failedCount,
  String? currentPath,
});

/// 串行为扫描目标生成并持久化封面缩略图；失败不中断，结束时汇总失败数。
class GenerateComicThumbnailsUseCase {
  GenerateComicThumbnailsUseCase({
    required ComicThumbnailService thumbnailService,
  }) : _thumbnailService = thumbnailService;

  static const int maxAttempts = 3;

  final ComicThumbnailService _thumbnailService;

  Future<GenerateComicThumbnailsResult> call({
    required List<Comic> targets,
    bool Function()? isCancelled,
    void Function(GenerateComicThumbnailsProgress progress)? onProgress,
  }) async {
    var done = 0;
    var failedCount = 0;
    for (final Comic comic in targets) {
      if (isCancelled?.call() == true) {
        break;
      }
      onProgress?.call((
        done: done,
        failedCount: failedCount,
        currentPath: comic.path,
      ));
      final bool succeeded = await _generateWithRetries(comic, isCancelled);
      done++;
      if (!succeeded) {
        failedCount++;
      }
      onProgress?.call((
        done: done,
        failedCount: failedCount,
        currentPath: comic.path,
      ));
    }
    return (failedCount: failedCount);
  }

  Future<bool> _generateWithRetries(
    Comic comic,
    bool Function()? isCancelled,
  ) async {
    for (var attempt = 0; attempt < maxAttempts; attempt++) {
      if (isCancelled?.call() == true) {
        return false;
      }
      final bytes = await _thumbnailService.resolveThumbnailBytes(comic);
      if (bytes != null && bytes.isNotEmpty) {
        return true;
      }
    }
    return false;
  }
}
