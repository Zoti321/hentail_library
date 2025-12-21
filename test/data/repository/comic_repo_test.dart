import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/repository/comic_repo.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart' as db;
import 'package:hentai_library/data/services/comic/comic.dart';
import 'package:hentai_library/domain/entity/entities.dart';
import 'package:mocktail/mocktail.dart';

class MockComicDao extends Mock implements ComicDao {}

class MockCategoryTagDao extends Mock implements CategoryTagDao {}

class MockComicSyncService extends Mock implements ComicSyncService {}

class MockComicFileCacheService extends Mock implements ComicFileCacheService {}

void main() {
  late MockComicDao comicDao;
  late MockCategoryTagDao categoryTagDao;
  late MockComicSyncService syncService;
  late MockComicFileCacheService cacheService;
  late ComicRepositoryImpl repo;

  setUp(() {
    comicDao = MockComicDao();
    categoryTagDao = MockCategoryTagDao();
    syncService = MockComicSyncService();
    cacheService = MockComicFileCacheService();
    repo = ComicRepositoryImpl(
      comicDao,
      categoryTagDao,
      syncService,
      cacheService,
    );
  });

  group('archiveChaptersToComic', () {
    test('moves chapters to target then deletes only empty comics not target', () async {
      const targetComicId = 'target';
      const emptyComicId = 'empty-comic';
      const chapterId1 = 'ch1';

      when(() => comicDao.updateChapterComic(any(), any())).thenAnswer((_) async => 1);

      final targetComic = db.Comic(
        id: 1,
        comicId: targetComicId,
        title: 'Target',
        isR18: false,
        totalViews: 0,
      );
      final emptyComic = db.Comic(
        id: 2,
        comicId: emptyComicId,
        title: 'Empty',
        isR18: false,
        totalViews: 0,
      );
      final oneChapter = db.Chapter(
        id: 1,
        chapterId: chapterId1,
        comicId: targetComicId,
        imageDir: '/dir',
      );
      final aggregate = {
        targetComicId: ComicWithChaptersAndTags(
          comic: targetComic,
          chapters: {oneChapter},
          tags: {},
        ),
        emptyComicId: ComicWithChaptersAndTags(
          comic: emptyComic,
          chapters: {},
          tags: {},
        ),
      };
      when(() => comicDao.getComicWithChaptersAndTags()).thenAnswer((_) async => aggregate);
      when(() => comicDao.deleteComic(any())).thenAnswer((_) async => 1);
      when(() => cacheService.clearComicCache(any())).thenAnswer((_) async => {});

      await repo.archiveChaptersToComic(
        ComicArchiveForm(comicId: targetComicId, chapterIds: [chapterId1]),
      );

      verify(() => comicDao.updateChapterComic(chapterId1, targetComicId)).called(1);
      verify(() => comicDao.getComicWithChaptersAndTags()).called(1);
      verify(() => comicDao.deleteComic(emptyComicId)).called(1);
      verify(() => cacheService.clearComicCache(emptyComicId)).called(1);
      verifyNever(() => comicDao.deleteComic(targetComicId));
      verifyNever(() => cacheService.clearComicCache(targetComicId));
    });
  });
}
