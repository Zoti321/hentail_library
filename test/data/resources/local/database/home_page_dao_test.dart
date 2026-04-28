import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/database/dao/dao.dart';
import 'package:hentai_library/database/database.dart';
import 'package:hentai_library/database/dao/home_page_dao_types.dart';
import 'package:hentai_library/model/enums.dart'
    show ContentRating, ResourceType;

void main() {
  group('HomePageDao', () {
    test('loadHomePageCounts returns aggregate row counts', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      final HomePageDao homePageDao = HomePageDao(db);
      final ReadingHistoryDao readingHistoryDao = ReadingHistoryDao(db);
      final SeriesReadingHistoryDao seriesHistoryDao = SeriesReadingHistoryDao(
        db,
      );
      addTearDown(() async {
        await db.close();
      });
      final ComicDao comicDao = ComicDao(db);
      await comicDao.upsertMany(<ComicsCompanion>[
        ComicsCompanion.insert(
          comicId: 'c1',
          path: p1,
          resourceType: ResourceType.dir,
          title: 'T1',
        ),
        ComicsCompanion.insert(
          comicId: 'c2',
          path: p2,
          resourceType: ResourceType.dir,
          title: 'T2',
        ),
      ]);
      await db.into(db.tags).insert(TagsCompanion.insert(name: 'tag1'));
      await db
          .into(db.seriesTable)
          .insert(SeriesTableCompanion.insert(name: 'S1'));
      final DateTime t0 = DateTime(2020, 1, 1);
      final DateTime t1 = DateTime(2021, 1, 1);
      final DateTime t2 = DateTime(2022, 1, 1);
      await readingHistoryDao.recordReading(
        ComicReadingHistoriesCompanion(
          comicId: const Value('c1'),
          title: const Value('T1'),
          lastReadTime: Value(t1),
        ),
      );
      await readingHistoryDao.recordReading(
        ComicReadingHistoriesCompanion(
          comicId: const Value('c2'),
          title: const Value('T2'),
          lastReadTime: Value(t0),
        ),
      );
      await seriesHistoryDao.recordSeriesReading(
        SeriesReadingHistoriesCompanion(
          seriesName: const Value('S1'),
          lastReadComicId: const Value('c1'),
          lastReadTime: Value(t2),
        ),
      );
      final HomePageCounts actual = await homePageDao.loadHomePageCounts();
      expect(actual.comicCount, 2);
      expect(actual.tagCount, 1);
      expect(actual.seriesCount, 1);
      expect(actual.readingRecordCount, 3);
    });
    test(
      'watchContinueReadingTop5 merges and orders by lastReadTime',
      () async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        final HomePageDao homePageDao = HomePageDao(db);
        final ReadingHistoryDao readingHistoryDao = ReadingHistoryDao(db);
        final SeriesReadingHistoryDao seriesHistoryDao =
            SeriesReadingHistoryDao(db);
        addTearDown(() async {
          await db.close();
        });
        final ComicDao comicDao = ComicDao(db);
        await comicDao.upsertMany(<ComicsCompanion>[
          ComicsCompanion.insert(
            comicId: 'a',
            path: p1,
            resourceType: ResourceType.dir,
            title: 'A',
          ),
          ComicsCompanion.insert(
            comicId: 'b',
            path: p2,
            resourceType: ResourceType.dir,
            title: 'B',
          ),
        ]);
        await db
            .into(db.seriesTable)
            .insert(SeriesTableCompanion.insert(name: 'S1'));
        final DateTime old = DateTime(2018, 1, 1);
        final DateTime mid = DateTime(2019, 1, 1);
        final DateTime newest = DateTime(2024, 1, 1);
        await seriesHistoryDao.recordSeriesReading(
          SeriesReadingHistoriesCompanion(
            seriesName: const Value('S1'),
            lastReadComicId: const Value('a'),
            lastReadTime: Value(old),
          ),
        );
        await readingHistoryDao.recordReading(
          ComicReadingHistoriesCompanion(
            comicId: const Value('a'),
            title: const Value('A'),
            lastReadTime: Value(newest),
          ),
        );
        await readingHistoryDao.recordReading(
          ComicReadingHistoriesCompanion(
            comicId: const Value('b'),
            title: const Value('B'),
            lastReadTime: Value(mid),
          ),
        );
        final List<HomeContinueReadingEntry> top = await homePageDao
            .watchContinueReadingTop5()
            .first;
        expect(top.length, 3);
        expect(
          top[0].kind == HomeContinueReadingKind.comic && top[0].comicId == 'a',
          isTrue,
        );
        expect(
          top[1].kind == HomeContinueReadingKind.comic && top[1].comicId == 'b',
          isTrue,
        );
        expect(
          top[2].kind == HomeContinueReadingKind.series &&
              top[2].seriesName == 'S1',
          isTrue,
        );
      },
    );
    test('loadHomeSeriesComicOrderMap uses series_items sortOrder', () async {
      final AppDatabase db = AppDatabase(NativeDatabase.memory());
      final HomePageDao homePageDao = HomePageDao(db);
      addTearDown(() async {
        await db.close();
      });
      final ComicDao comicDao = ComicDao(db);
      await comicDao.upsertMany(<ComicsCompanion>[
        ComicsCompanion.insert(
          comicId: 'a',
          path: p1,
          resourceType: ResourceType.dir,
          title: 'A',
        ),
        ComicsCompanion.insert(
          comicId: 'b',
          path: p2,
          resourceType: ResourceType.dir,
          title: 'B',
        ),
      ]);
      await db
          .into(db.seriesTable)
          .insert(SeriesTableCompanion.insert(name: 'SX'));
      await db
          .into(db.seriesItems)
          .insert(
            SeriesItemsCompanion.insert(
              seriesName: 'SX',
              comicId: 'a',
              sortOrder: 0,
            ),
          );
      await db
          .into(db.seriesItems)
          .insert(
            SeriesItemsCompanion.insert(
              seriesName: 'SX',
              comicId: 'b',
              sortOrder: 1,
            ),
          );
      final Map<String, int> orderMap = await homePageDao
          .loadHomeSeriesComicOrderMap();
      expect(orderMap['SX|a'], 0);
      expect(orderMap['SX|b'], 1);
    });
    test(
      'loadHomePageCountsHealthy excludes r18 comics and r18-tainted series',
      () async {
        final AppDatabase db = AppDatabase(NativeDatabase.memory());
        final HomePageDao homePageDao = HomePageDao(db);
        addTearDown(() async {
          await db.close();
        });
        final ComicDao comicDao = ComicDao(db);
        await comicDao.upsertMany(<ComicsCompanion>[
          ComicsCompanion.insert(
            comicId: 'safe1',
            path: p1,
            resourceType: ResourceType.dir,
            title: 'S1',
          ),
          ComicsCompanion.insert(
            comicId: 'r18a',
            path: p2,
            resourceType: ResourceType.dir,
            title: 'R1',
            contentRating: const Value(ContentRating.r18),
          ),
          ComicsCompanion.insert(
            comicId: 'r18b',
            path: p3,
            resourceType: ResourceType.dir,
            title: 'R2',
            contentRating: const Value(ContentRating.r18),
          ),
        ]);
        await db
            .into(db.tags)
            .insert(
              TagsCompanion.insert(name: 't2'),
              mode: InsertMode.insertOrIgnore,
            );
        await db
            .into(db.comicTags)
            .insert(ComicTagsCompanion.insert(comicId: 'r18a', tagName: 't2'));
        await db
            .into(db.seriesTable)
            .insert(SeriesTableCompanion.insert(name: 'SerOk'));
        await db
            .into(db.seriesTable)
            .insert(SeriesTableCompanion.insert(name: 'SerR18'));
        await db
            .into(db.seriesItems)
            .insert(
              SeriesItemsCompanion.insert(
                seriesName: 'SerOk',
                comicId: 'safe1',
                sortOrder: 0,
              ),
            );
        await db
            .into(db.seriesItems)
            .insert(
              SeriesItemsCompanion.insert(
                seriesName: 'SerR18',
                comicId: 'r18b',
                sortOrder: 0,
              ),
            );
        final HomePageCounts healthy = await homePageDao
            .loadHomePageCountsHealthy();
        expect(healthy.comicCount, 1);
        expect(healthy.tagCount, 1);
        expect(healthy.seriesCount, 1);
      },
    );
  });
}

const String p1 = r'C:\c1';
const String p2 = r'C:\c2';
const String p3 = r'C:\c3';
