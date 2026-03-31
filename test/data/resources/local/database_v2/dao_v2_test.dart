import 'package:drift/native.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:hentai_library/domain/util/enums.dart';
import 'package:test/test.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/resources/local/database/database.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';

void main() {
  group('v2 dao', () {
    late AppDatabase db;
    late LibraryComicDao comicDao;
    late LibrarySeriesDao seriesDao;
    late LibraryTagDao tagDao;

    setUp(() {
      db = AppDatabase(NativeDatabase.memory());
      comicDao = LibraryComicDao(db);
      seriesDao = LibrarySeriesDao(db);
      tagDao = LibraryTagDao(db);
    });

    tearDown(() async {
      await db.close();
    });

    test('assignComicExclusive 保证同一 comicId 只属于一个 series', () async {
      await seriesDao.createSeries(
        LibrarySeriesCompanion.insert(seriesId: 's1', name: 'A'),
      );
      await seriesDao.createSeries(
        LibrarySeriesCompanion.insert(seriesId: 's2', name: 'B'),
      );

      await seriesDao.assignComicExclusive(
        comicId: 'c1',
        targetSeriesId: 's1',
        sortOrder: 1,
      );
      await seriesDao.assignComicExclusive(
        comicId: 'c1',
        targetSeriesId: 's2',
        sortOrder: 5,
      );

      final aItems = await seriesDao.getItemsForSeries('s1');
      final bItems = await seriesDao.getItemsForSeries('s2');

      expect(aItems, isEmpty);
      expect(bItems.length, 1);
      expect(bItems.single.comicId, 'c1');
      expect(bItems.single.sortOrder, 5);
    });

    test('tag rename 会同步更新 comic-tags 关联', () async {
      await tagDao.addTag('old');

      await comicDao.upsertMany([
        LibraryComicsCompanion.insert(
          comicId: 'c1',
          path: r'X:\a\b',
          resourceType: ResourceType.dir,
          title: 't',
          authorsJson: const Value(<String>['a']),
          contentRating: const Value(ContentRating.safe),
        ),
      ]);
      await comicDao.replaceComicTags('c1', ['old']);

      await tagDao.renameTag('old', 'new');

      final tagRows = await tagDao.listAll();
      expect(tagRows.map((e) => e.name), contains('new'));
      expect(tagRows.map((e) => e.name), isNot(contains('old')));

      final names = await comicDao.getTagNamesForComic('c1');
      expect(names, ['new']);
    });

    test('updateUserMeta 覆盖 title/authors/contentRating', () async {
      await comicDao.upsertMany([
        LibraryComicsCompanion.insert(
          comicId: 'c1',
          path: r'X:\a\b',
          resourceType: ResourceType.zip,
          title: 't1',
          authorsJson: const Value(<String>['a1']),
          contentRating: const Value(ContentRating.safe),
        ),
      ]);

      await comicDao.updateUserMeta(
        'c1',
        title: const Value('t2'),
        authors: const Value(<String>['a2', 'a3']),
        contentRating: const Value(ContentRating.r18),
      );

      final row = await comicDao.findById('c1');
      expect(row, isNotNull);
      expect(row!.title, 't2');
      expect(row.authorsJson, ['a2', 'a3']);
      expect(row.contentRating, ContentRating.r18);
    });
  });
}
