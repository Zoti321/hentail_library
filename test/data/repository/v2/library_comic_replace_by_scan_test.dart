import 'package:drift/native.dart';
import 'package:hentai_library/data/repository/library_comic_repo_impl.dart';
import 'package:hentai_library/data/repository/library_series_repo_impl.dart';
import 'package:hentai_library/data/repository/reading_history_repo.dart';
import 'package:hentai_library/data/repository/reading_session_repo.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart'
    as db;
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:test/test.dart';

void main() {
  group('LibraryComicRepositoryImpl.replaceByScan', () {
    late db.AppDatabase dbInstance;
    late LibraryComicRepositoryImpl comicRepo;

    setUp(() {
      dbInstance = db.AppDatabase(NativeDatabase.memory());
      final seriesRepo = LibrarySeriesRepositoryImpl(
        LibrarySeriesDao(dbInstance),
      );
      comicRepo = LibraryComicRepositoryImpl(
        LibraryComicDao(dbInstance),
        readingHistory: ReadingHistoryRepositoryImpl(
          ReadingHistoryDao(dbInstance),
        ),
        librarySeries: seriesRepo,
        readingSessions: ReadingSessionRepositoryImpl(
          ReadingSessionDao(dbInstance),
        ),
      );
    });

    tearDown(() async {
      await dbInstance.close();
    });

    test('删除扫描未包含的条目', () async {
      await comicRepo.upsertMany([
        Comic(
          comicId: 'gone',
          path: r'X:\gone',
          resourceType: ResourceType.dir,
          title: 'gone',
        ),
      ]);

      final r = await comicRepo.replaceByScan([
        Comic(
          comicId: 'stay',
          path: r'Y:\stay',
          resourceType: ResourceType.dir,
          title: 'stay',
        ),
      ]);

      expect(r.removedCount, 1);
      expect(r.addedCount, 1);
      expect(r.keptCount, 0);

      final all = await comicRepo.getAll();
      expect(all.map((e) => e.comicId).toSet(), {'stay'});
    });

    test('kept 合并保留用户标题', () async {
      await comicRepo.upsertMany([
        Comic(
          comicId: 'k1',
          path: r'C:\old',
          resourceType: ResourceType.dir,
          title: 'user title',
        ),
      ]);

      final r = await comicRepo.replaceByScan([
        Comic(
          comicId: 'k1',
          path: r'C:\new',
          resourceType: ResourceType.zip,
          title: 'parsed title',
        ),
      ]);

      expect(r.removedCount, 0);
      expect(r.addedCount, 0);
      expect(r.keptCount, 1);

      final c = await comicRepo.findById('k1');
      expect(c, isNotNull);
      expect(c!.path, r'C:\new');
      expect(c.resourceType, ResourceType.zip);
      expect(c.title, 'user title');
    });

    test('getAllComicIds 与列表长度一致', () async {
      await comicRepo.upsertMany([
        Comic(
          comicId: 'a',
          path: r'P:\a',
          resourceType: ResourceType.dir,
          title: 'a',
        ),
        Comic(
          comicId: 'b',
          path: r'P:\b',
          resourceType: ResourceType.dir,
          title: 'b',
        ),
      ]);
      final ids = await LibraryComicDao(dbInstance).getAllComicIds();
      expect(ids.toSet(), {'a', 'b'});
    });
  });
}
