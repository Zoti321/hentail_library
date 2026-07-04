import 'dart:typed_data';

import 'package:hentai_library/src/rust/api/thumbnail.dart';

typedef ComicThumbnailRecord = ({
  Uint8List thumbnail,
  int sourceModifiedMs,
  int sourceSize,
});

abstract class ComicThumbnailRepository {
  Future<ComicThumbnailRecord?> findByComicId(String comicId);

  Future<ComicThumbnailRecord?> ensureByComicId({
    required String comicId,
    required ThumbnailPriorityDto priority,
  });

  Future<void> upsert({
    required String comicId,
    required Uint8List thumbnail,
    required int sourceModifiedMs,
    required int sourceSize,
  });

  Future<void> deleteByComicIds(List<String> comicIds);
}
