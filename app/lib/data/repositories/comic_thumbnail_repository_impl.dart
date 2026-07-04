import 'dart:typed_data';

import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/domain/repositories/comic_thumbnail_repository.dart';
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
      sourceModifiedMs: row.sourceModifiedMs,
      sourceSize: row.sourceSize,
    );
  }

  @override
  Future<ComicThumbnailRecord?> ensureByComicId({
    required String comicId,
    required rust.ThumbnailPriorityDto priority,
  }) async {
    final rust.ComicThumbnailDto? row = guardFrbSync(
      () => rust.ensureThumbnailByComicIdFrb(
        comicId: comicId,
        priority: priority,
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
    );
  }

  @override
  Future<void> upsert({
    required String comicId,
    required Uint8List thumbnail,
    required int sourceModifiedMs,
    required int sourceSize,
  }) {
    throw UnsupportedError('缩略图写入由 Rust sync 负责');
  }

  @override
  Future<void> deleteByComicIds(List<String> comicIds) async {
    guardFrbSync(
      () => rust.deleteThumbnailsByComicIdsFrb(comicIds: comicIds),
      fallbackMessage: '删除缩略图失败',
    );
  }
}
