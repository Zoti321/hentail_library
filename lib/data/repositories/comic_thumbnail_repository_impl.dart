import 'dart:typed_data';

import 'package:hentai_library/data/database/dao/dao.dart';
import 'package:hentai_library/data/database/database.dart';
import 'package:hentai_library/domain/repositories/comic_thumbnail_repository.dart';

class ComicThumbnailRepositoryImpl implements ComicThumbnailRepository {
  ComicThumbnailRepositoryImpl(this._dao);

  final ComicThumbnailDao _dao;

  @override
  Future<ComicThumbnailRecord?> findByComicId(String comicId) async {
    final DbComicThumbnail? row = await _dao.findByComicId(comicId);
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
  Future<void> upsert({
    required String comicId,
    required Uint8List thumbnail,
    required int sourceModifiedMs,
    required int sourceSize,
  }) {
    return _dao.upsert(
      comicId: comicId,
      thumbnail: thumbnail,
      sourceModifiedMs: sourceModifiedMs,
      sourceSize: sourceSize,
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<void> deleteByComicIds(List<String> comicIds) {
    return _dao.deleteByComicIds(comicIds);
  }
}
