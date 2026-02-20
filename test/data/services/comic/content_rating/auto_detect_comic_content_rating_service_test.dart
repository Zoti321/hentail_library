import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/resources/local/database/dao/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/data/services/comic/content_rating/auto_detect_comic_content_rating_service.dart';
import 'package:hentai_library/domain/util/enums.dart';

void main() {
  group('AutoDetectComicContentRatingService', () {
    test('marks comics as r18 when paths match keywords', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      final ComicDao comicDao = ComicDao(db);
      addTearDown(() async {
        await db.close();
      });
      await comicDao.upsertMany(<ComicsCompanion>[
        ComicsCompanion.insert(
          comicId: 'a',
          path: r'E:\涩涩\本子\Analic Angel',
          resourceType: ResourceType.dir,
          title: 'A',
        ),
        ComicsCompanion.insert(
          comicId: 'b',
          path: r'D:\Books\Safe\Series',
          resourceType: ResourceType.dir,
          title: 'B',
        ),
        ComicsCompanion.insert(
          comicId: 'c',
          path: r'E:\NSFW\Folder\Comic',
          resourceType: ResourceType.dir,
          title: 'C',
        ),
      ]);
      final AutoDetectComicContentRatingService service =
          AutoDetectComicContentRatingService(comicDao: comicDao);
      final AutoDetectComicContentRatingResult actualResult = await service
          .executeAutoDetect();
      expect(actualResult.totalComics, 3);
      expect(actualResult.matchedComics, 2);
      expect(actualResult.updatedComics, 2);
      final List<DbComic> actualComics = await comicDao.getAllComics();
      final Map<String, ContentRating> ratingById = <String, ContentRating>{
        for (final DbComic comic in actualComics)
          comic.comicId: comic.contentRating,
      };
      expect(ratingById['a'], ContentRating.r18);
      expect(ratingById['c'], ContentRating.r18);
      expect(ratingById['b'], ContentRating.unknown);
    });

    test('returns zero updates when no path matches keywords', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      final ComicDao comicDao = ComicDao(db);
      addTearDown(() async {
        await db.close();
      });
      await comicDao.upsertMany(<ComicsCompanion>[
        ComicsCompanion.insert(
          comicId: 'x',
          path: r'D:\Safe\Artbooks',
          resourceType: ResourceType.dir,
          title: 'X',
        ),
      ]);
      final AutoDetectComicContentRatingService service =
          AutoDetectComicContentRatingService(comicDao: comicDao);
      final AutoDetectComicContentRatingResult actualResult = await service
          .executeAutoDetect();
      expect(actualResult.totalComics, 1);
      expect(actualResult.matchedComics, 0);
      expect(actualResult.updatedComics, 0);
      final DbComic? actualComic = await comicDao.findById('x');
      expect(actualComic, isNotNull);
      expect(actualComic!.contentRating, ContentRating.unknown);
    });
  });
}
