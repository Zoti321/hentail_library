import 'dart:typed_data';

typedef ComicThumbnailRecord = ({
  Uint8List thumbnail,
  int sourceModifiedMs,
  int sourceSize,
});

abstract class ComicThumbnailRepository {
  Future<ComicThumbnailRecord?> findByComicId(String comicId);

  Future<void> upsert({
    required String comicId,
    required Uint8List thumbnail,
    required int sourceModifiedMs,
    required int sourceSize,
  });

  Future<void> deleteByComicIds(List<String> comicIds);
}
