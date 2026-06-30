import 'dart:typed_data';

import 'package:hentai_library/data/services/comic/thumbnail/comic_thumbnail_generation_policy.dart';
import 'package:hentai_library/data/services/comic/thumbnail/comic_thumbnail_generator.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/repositories/comic_thumbnail_repository.dart';

/// 按需生成并缓存漫画封面缩略图；同 comicId 并发去重。
class ComicThumbnailService {
  ComicThumbnailService(this._repository);

  final ComicThumbnailRepository _repository;
  final Map<String, Future<Uint8List?>> _inFlight =
      <String, Future<Uint8List?>>{};

  Future<bool> needsThumbnailGeneration(Comic comic) =>
      needsComicThumbnailGeneration(comic: comic, repository: _repository);

  Future<Uint8List?> resolveThumbnailBytes(Comic comic) async {
    if (!canGenerateComicThumbnail(comic.resourceType)) {
      return null;
    }
    final ComicSourceStat? sourceStat = await readComicSourceStat(
      path: comic.path,
      type: comic.resourceType,
    );
    if (sourceStat == null) {
      return null;
    }
    final ComicThumbnailRecord? cached = await _repository.findByComicId(
      comic.comicId,
    );
    if (cached != null &&
        cached.sourceModifiedMs == sourceStat.modifiedMs &&
        cached.sourceSize == sourceStat.size) {
      return cached.thumbnail;
    }
    return _runDeduped(comic.comicId, () async {
      final Uint8List? generated = await generateComicThumbnailJpegOffMainUi(
        path: comic.path,
        type: comic.resourceType,
      );
      if (generated == null || generated.isEmpty) {
        return null;
      }
      await _repository.upsert(
        comicId: comic.comicId,
        thumbnail: generated,
        sourceModifiedMs: sourceStat.modifiedMs,
        sourceSize: sourceStat.size,
      );
      return generated;
    });
  }

  Future<Uint8List?> _runDeduped(
    String comicId,
    Future<Uint8List?> Function() task,
  ) {
    final Future<Uint8List?>? existing = _inFlight[comicId];
    if (existing != null) {
      return existing;
    }
    final Future<Uint8List?> future = task().whenComplete(() {
      _inFlight.remove(comicId);
    });
    _inFlight[comicId] = future;
    return future;
  }
}
