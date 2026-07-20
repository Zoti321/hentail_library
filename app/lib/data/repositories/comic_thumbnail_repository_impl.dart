import 'dart:typed_data';

import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/adapters/thumbnail_frb_mapper.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_thumbnail_repository.dart';
import 'package:hentai_library/domain/thumbnail/series_cover_source.dart';
import 'package:hentai_library/domain/thumbnail/thumbnail_event.dart';
import 'package:hentai_library/src/rust/api/thumbnail.dart' as rust;

class ComicThumbnailRepositoryImpl implements ComicThumbnailRepository {
  const ComicThumbnailRepositoryImpl();

  @override
  Future<ComicThumbnailRecord?> findByComicId(String comicId) async {
    final rust.ComicThumbnailDto? row = guardFrbSync(
      () => rust.findThumbnailByComicIdFrb(comicId: comicId),
      fallbackMessage: '读取缩略图失败',
    );
    if (row == null) {
      return null;
    }
    return (
      thumbnail: Uint8List.fromList(row.thumbnail),
      sourceModifiedMs: row.sourceModifiedMs.toInt(),
      sourceSize: row.sourceSize.toInt(),
      isUserSet: row.isUserSet,
    );
  }

  @override
  Future<ComicThumbnailRecord?> ensureByComicId({
    required String comicId,
    required ThumbnailPriority priority,
  }) async {
    final rust.ComicThumbnailDto? row = guardFrbSync(
      () => rust.ensureThumbnailByComicIdFrb(
        comicId: comicId,
        priority: mapThumbnailPriority(priority),
      ),
      fallbackMessage: '生成缩略图失败',
    );
    if (row == null) {
      return null;
    }
    return (
      thumbnail: Uint8List.fromList(row.thumbnail),
      sourceModifiedMs: row.sourceModifiedMs.toInt(),
      sourceSize: row.sourceSize.toInt(),
      isUserSet: row.isUserSet,
    );
  }

  @override
  Future<void> setComicCoverFromPage({
    required String comicId,
    required String path,
    required String resourceType,
    required int pageIndex,
  }) async {
    guardFrbSync(
      () => rust.setComicThumbnailFromPageFrb(
        comicId: comicId,
        path: path,
        resourceType: resourceType,
        pageIndex: pageIndex,
      ),
      fallbackMessage: '设置漫画封面失败',
    );
  }

  @override
  Future<void> setSeriesCoverFromPage({
    required String seriesId,
    required String comicId,
    required String path,
    required String resourceType,
    required int pageIndex,
  }) async {
    guardFrbSync(
      () => rust.setSeriesThumbnailFromPageFrb(
        seriesId: seriesId,
        comicId: comicId,
        path: path,
        resourceType: resourceType,
        pageIndex: pageIndex,
      ),
      fallbackMessage: '设置系列封面失败',
    );
  }

  @override
  Future<SeriesCoverSource> resolveSeriesCover(String seriesId) async {
    final rust.SeriesCoverSourceDto dto = guardFrbSync(
      () => rust.resolveSeriesCoverFrb(seriesId: seriesId),
      fallbackMessage: '解析系列封面失败',
    );
    return switch (dto) {
      rust.SeriesCoverSourceDto_CustomThumbnail(:final Uint8List thumbnail) =>
        SeriesCoverCustomThumbnail(Uint8List.fromList(thumbnail)),
      rust.SeriesCoverSourceDto_FallbackComic(:final String comicId) =>
        SeriesCoverFallbackComic(comicId),
      rust.SeriesCoverSourceDto_Missing() => const SeriesCoverMissing(),
    };
  }

  @override
  Future<void> deleteByComicIds(List<String> comicIds) async {
    guardFrbSync(
      () => rust.deleteThumbnailsByComicIdsFrb(comicIds: comicIds),
      fallbackMessage: '删除缩略图失败',
    );
  }

  @override
  Stream<ThumbnailEvent> watchEvents() {
    return guardFrbStream(
      rust.watchThumbnailEventsFrb,
      fallbackMessage: '缩略图事件流失败',
    ).map(mapThumbnailEvent);
  }
}
