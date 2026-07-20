import 'dart:typed_data';

import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/domain/thumbnail/thumbnail_event.dart';

typedef ComicThumbnailRecord = ({
  Uint8List thumbnail,
  int sourceModifiedMs,
  int sourceSize,
  bool isUserSet,
});

abstract class ComicThumbnailRepository {
  Future<ComicThumbnailRecord?> findByComicId(String comicId);

  Future<ComicThumbnailRecord?> ensureByComicId({
    required String comicId,
    required ThumbnailPriority priority,
  });

  /// 将漫画指定页（0-based）设为漫画封面。
  Future<void> setComicCoverFromPage({
    required String comicId,
    required String path,
    required String resourceType,
    required int pageIndex,
  });

  /// 将漫画指定页（0-based）设为系列封面。
  Future<void> setSeriesCoverFromPage({
    required String seriesId,
    required String comicId,
    required String path,
    required String resourceType,
    required int pageIndex,
  });

  Future<SeriesCoverSource> resolveSeriesCover(String seriesId);

  Future<void> deleteByComicIds(List<String> comicIds);

  Stream<ThumbnailEvent> watchEvents();
}
