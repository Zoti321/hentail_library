import 'package:hentai_library/data/services/comic/thumbnail/comic_thumbnail_generator.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/repositories/comic_thumbnail_repository.dart';

/// 与 [ComicThumbnailService.resolveThumbnailBytes] 一致的失效判定；不 decode 缩略图。
Future<bool> needsComicThumbnailGeneration({
  required Comic comic,
  required ComicThumbnailRepository repository,
}) async {
  if (!canGenerateComicThumbnail(comic.resourceType)) {
    return false;
  }
  final ComicSourceStat? sourceStat = await readComicSourceStat(
    path: comic.path,
    type: comic.resourceType,
  );
  if (sourceStat == null) {
    return false;
  }
  final ComicThumbnailRecord? cached = await repository.findByComicId(
    comic.comicId,
  );
  if (cached == null) {
    return true;
  }
  return cached.sourceModifiedMs != sourceStat.modifiedMs ||
      cached.sourceSize != sourceStat.size;
}
