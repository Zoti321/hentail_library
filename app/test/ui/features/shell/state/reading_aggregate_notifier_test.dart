import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/models/entity/series_reading_history.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/reading/read_session.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/domain/repositories/series_reading_history_repository.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/reading_aggregate_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

class _RecordingReadingHistoryRepo implements ReadingHistoryRepository {
  final List<ReadingHistory> records = <ReadingHistory>[];

  @override
  Future<void> recordReading(ReadingHistory history) async {
    records.add(history);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingSeriesReadingHistoryRepo
    implements SeriesReadingHistoryRepository {
  final List<SeriesReadingHistory> records = <SeriesReadingHistory>[];

  @override
  Future<void> recordSeriesReading(SeriesReadingHistory history) async {
    records.add(history);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Comic _comic({String id = 'c1', String title = 'Test Comic'}) {
  final DateTime now = DateTime.utc(2026, 1, 1);
  return Comic(
    comicId: id,
    path: '/tmp/$id',
    resourceType: ResourceType.zip,
    resourceSize: 1024,
    createdAt: now,
    lastUpdatedAt: now,
    title: title,
    pageCount: 10,
  );
}

void main() {
  late _RecordingReadingHistoryRepo readingRepo;
  late _RecordingSeriesReadingHistoryRepo seriesRepo;
  late ProviderContainer container;

  setUp(() {
    readingRepo = _RecordingReadingHistoryRepo();
    seriesRepo = _RecordingSeriesReadingHistoryRepo();
    container = ProviderContainer(
      overrides: <Override>[
        readingHistoryRepoProvider.overrideWith((Ref ref) => readingRepo),
        seriesReadingHistoryRepoProvider.overrideWith((Ref ref) => seriesRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  ReadingAggregateNotifier notifier() =>
      container.read(readingAggregateProvider.notifier);

  test('incognito beginSession is no-op', () async {
    await notifier().beginSession(
      comic: _comic(),
      mode: ReadSessionMode.standalone,
      incognito: true,
      initialPageIndex: 3,
    );

    expect(readingRepo.records, isEmpty);
    expect(seriesRepo.records, isEmpty);
    expect(notifier().hasActiveSession, isFalse);
  });

  test('standalone beginSession writes comic history', () async {
    await notifier().beginSession(
      comic: _comic(),
      mode: ReadSessionMode.standalone,
      initialPageIndex: 2,
    );

    expect(readingRepo.records, hasLength(1));
    expect(readingRepo.records.single.comicId, 'c1');
    expect(readingRepo.records.single.pageIndex, 2);
    expect(seriesRepo.records, isEmpty);
    expect(notifier().hasActiveSession, isTrue);
  });

  test('series mode writes comic and series history', () async {
    await notifier().beginSession(
      comic: _comic(),
      mode: ReadSessionMode.series,
      seriesId: 's1',
      initialPageIndex: 4,
    );

    expect(readingRepo.records, hasLength(1));
    expect(readingRepo.records.single.pageIndex, 4);
    expect(seriesRepo.records, hasLength(1));
    expect(seriesRepo.records.single.seriesId, 's1');
    expect(seriesRepo.records.single.lastReadComicId, 'c1');
    expect(seriesRepo.records.single.pageIndex, 4);
  });

  test('updatePage and flushProgress persist latest page', () async {
    await notifier().beginSession(
      comic: _comic(),
      mode: ReadSessionMode.standalone,
      initialPageIndex: 1,
    );
    readingRepo.records.clear();

    notifier().updatePage(7);
    await notifier().flushProgress();

    expect(readingRepo.records, hasLength(1));
    expect(readingRepo.records.single.pageIndex, 7);
  });

  test('endSession clears active session after flush', () async {
    await notifier().beginSession(
      comic: _comic(),
      mode: ReadSessionMode.standalone,
      initialPageIndex: 3,
    );
    readingRepo.records.clear();

    notifier().updatePage(5);
    await notifier().endSession();

    expect(readingRepo.records, hasLength(1));
    expect(readingRepo.records.single.pageIndex, 5);
    expect(notifier().hasActiveSession, isFalse);
  });
}
