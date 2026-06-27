part of 'dao.dart';

@DriftAccessor(tables: [ComicThumbnails])
class ComicThumbnailDao extends DatabaseAccessor<AppDatabase>
    with _$ComicThumbnailDaoMixin {
  ComicThumbnailDao(super.db);

  Future<DbComicThumbnail?> findByComicId(String comicId) {
    return (select(comicThumbnails)
          ..where((ComicThumbnails t) => t.comicId.equals(comicId)))
        .getSingleOrNull();
  }

  Future<void> upsert({
    required String comicId,
    required Uint8List thumbnail,
    required int sourceModifiedMs,
    required int sourceSize,
    required DateTime updatedAt,
  }) async {
    await into(comicThumbnails).insertOnConflictUpdate(
      ComicThumbnailsCompanion.insert(
        comicId: comicId,
        thumbnail: thumbnail,
        sourceModifiedMs: sourceModifiedMs,
        sourceSize: sourceSize,
        updatedAt: updatedAt,
      ),
    );
  }

  Future<void> deleteByComicIds(List<String> comicIds) async {
    if (comicIds.isEmpty) {
      return;
    }
    await (delete(comicThumbnails)
          ..where((ComicThumbnails t) => t.comicId.isIn(comicIds)))
        .go();
  }
}
