import 'package:drift/native.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:test/test.dart';
import 'package:hentai_library/data/repository/comic_repo_impl.dart';
import 'package:hentai_library/data/repository/series_repo_impl.dart';
import 'package:hentai_library/data/repository/tag_repo_impl.dart';
import 'package:hentai_library/data/repository/reading_history_repo.dart';
import 'package:hentai_library/data/repository/reading_session_repo.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart'
    as db;
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/entity/comic/comic.dart' as entity;
import 'package:hentai_library/domain/entity/comic/tag.dart' as entity;

void main() {
  group('v2 repos', () {
    late db.AppDatabase dbInstance;
    late ComicRepositoryImpl comicRepo;
    late SeriesRepositoryImpl seriesRepo;
    late TagRepositoryImpl tagRepo;

    setUp(() {
      dbInstance = db.AppDatabase(NativeDatabase.memory());
      seriesRepo = SeriesRepositoryImpl(LibrarySeriesDao(dbInstance));
      comicRepo = ComicRepositoryImpl(
        LibraryComicDao(dbInstance),
        readingHistory: ReadingHistoryRepositoryImpl(
          ReadingHistoryDao(dbInstance),
        ),
        librarySeries: seriesRepo,
        readingSessions: ReadingSessionRepositoryImpl(
          ReadingSessionDao(dbInstance),
        ),
      );
      tagRepo = TagRepositoryImpl(LibraryTagDao(dbInstance));
    });

    tearDown(() async {
      await dbInstance.close();
    });

    test('LibraryTagRepository.rename 会级联更新 comic tags', () async {
      await tagRepo.add(entity.Tag(name: 'old'));

      await comicRepo.upsertMany([
        entity.Comic(
          comicId: 'c1',
          path: r'X:\a\b',
          resourceType: ResourceType.dir,
          title: 't',
          authors: ['a'],
          contentRating: ContentRating.safe,
          tags: [entity.Tag(name: 'old')],
        ),
      ]);

      await tagRepo.rename('old', 'new');

      final comic = await comicRepo.findById('c1');
      expect(comic, isNotNull);
      expect(comic!.tags.map((e) => e.name).toList(), ['new']);
    });

    test('LibrarySeriesRepository.assignComicExclusive 排他归属生效', () async {
      await seriesRepo.create('A');
      await seriesRepo.create('B');

      final all = await seriesRepo.getAll();
      expect(all.length, 2);

      final s1 = all[0].seriesId;
      final s2 = all[1].seriesId;

      await seriesRepo.assignComicExclusive(
        comicId: 'c1',
        targetSeriesId: s1,
        order: 1,
      );
      await seriesRepo.assignComicExclusive(
        comicId: 'c1',
        targetSeriesId: s2,
        order: 2,
      );

      final s1After = await seriesRepo.findById(s1);
      final s2After = await seriesRepo.findById(s2);

      expect(s1After!.items.where((i) => i.comicId == 'c1'), isEmpty);
      expect(s2After!.items.where((i) => i.comicId == 'c1').length, 1);
    });
  });
}
