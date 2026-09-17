import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/domain/reading/series_reading_context.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_detail_series_nav_provider.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

class _FakeLibraryRevision extends LibraryRevision {
  @override
  LibraryRevisionState build() {
    return const LibraryRevisionState(revision: 1, hasReceivedFirstEmit: true);
  }
}

class _FakeComicRepo implements ComicRepository {
  _FakeComicRepo(this._titles);

  final Map<String, String> _titles;
  final List<List<String>> findByIdsCalls = <List<String>>[];
  int findByIdCalls = 0;

  Comic _comic(String comicId, String title) {
    return Comic(
      comicId: comicId,
      path: '/comics/$comicId',
      resourceType: ResourceType.dir,
      resourceSize: 0,
      createdAt: DateTime.utc(2024),
      lastUpdatedAt: DateTime.utc(2024),
      title: title,
      pageCount: 1,
    );
  }

  @override
  Future<Comic?> findById(String comicId) async {
    findByIdCalls += 1;
    final String? title = _titles[comicId];
    if (title == null) {
      return null;
    }
    return _comic(comicId, title);
  }

  @override
  Future<List<Comic>> findByIds(List<String> comicIds) async {
    findByIdsCalls.add(List<String>.from(comicIds));
    final List<Comic> found = <Comic>[];
    for (final String comicId in comicIds) {
      final String? title = _titles[comicId];
      if (title != null) {
        found.add(_comic(comicId, title));
      }
    }
    return found;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSeriesRepo implements SeriesRepository {
  _FakeSeriesRepo(this._series);

  final List<Series> _series;

  @override
  Future<Series?> findById(String seriesId) async {
    for (final Series series in _series) {
      if (series.id == seriesId) {
        return series;
      }
    }
    return null;
  }

  @override
  Future<SeriesReadingContext?> getReadingContextByComicId(
    String comicId,
  ) async {
    for (final Series series in _series) {
      if (!series.items.any((SeriesItem item) => item.comicId == comicId)) {
        continue;
      }
      final List<SeriesItem> sorted = List<SeriesItem>.from(series.items)
        ..sort((SeriesItem a, SeriesItem b) => a.order.compareTo(b.order));
      final List<String> orderedComicIds = sorted
          .map((SeriesItem item) => item.comicId)
          .toList(growable: false);
      return (
        seriesId: series.id,
        seriesName: series.name,
        orderedComicIds: orderedComicIds,
        currentIndex: orderedComicIds.indexOf(comicId),
      );
    }
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Series _testSeries() {
  return Series(
    id: 'series-1',
    name: 'Test Series',
    folderPath: '/series',
    items: <SeriesItem>[
      SeriesItem(comicId: 'comic-a', order: 0.0),
      SeriesItem(comicId: 'comic-b', order: 1.0),
      SeriesItem(comicId: 'comic-c', order: 2.0),
    ],
  );
}

void main() {
  late Series series;
  late _FakeComicRepo comicRepo;
  late ProviderContainer container;

  setUp(() {
    series = _testSeries();
    comicRepo = _FakeComicRepo(<String, String>{
      'comic-a': 'Alpha',
      'comic-b': 'Beta',
      'comic-c': 'Gamma',
    });
    container = ProviderContainer(
      overrides: <Override>[
        libraryRevisionProvider.overrideWith(_FakeLibraryRevision.new),
        comicRepoProvider.overrideWith((Ref ref) => comicRepo),
        seriesRepoProvider.overrideWith(
          (Ref ref) => _FakeSeriesRepo(<Series>[series]),
        ),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('comicDetailSeriesNavForSeriesProvider', () {
    test('caches series navigation data by series id', () async {
      final ComicDetailSeriesNavSeriesData? first = await container.read(
        comicDetailSeriesNavForSeriesProvider('series-1').future,
      );
      final ComicDetailSeriesNavSeriesData? second = await container.read(
        comicDetailSeriesNavForSeriesProvider('series-1').future,
      );

      expect(first, isNotNull);
      expect(identical(first, second), isTrue);
      expect(first!.items.map((item) => item.title).toList(), <String>[
        'Alpha',
        'Beta',
        'Gamma',
      ]);
      expect(comicRepo.findByIdsCalls, <List<String>>[
        <String>['comic-a', 'comic-b', 'comic-c'],
      ]);
      expect(comicRepo.findByIdCalls, 0);
    });

    test('uses truncated id fallback for missing comics', () async {
      comicRepo = _FakeComicRepo(<String, String>{
        'comic-a': 'Alpha',
        'comic-c': 'Gamma',
      });
      container.dispose();
      container = ProviderContainer(
        overrides: <Override>[
          libraryRevisionProvider.overrideWith(_FakeLibraryRevision.new),
          comicRepoProvider.overrideWith((Ref ref) => comicRepo),
          seriesRepoProvider.overrideWith(
            (Ref ref) => _FakeSeriesRepo(<Series>[series]),
          ),
        ],
      );

      final ComicDetailSeriesNavSeriesData? data = await container.read(
        comicDetailSeriesNavForSeriesProvider('series-1').future,
      );

      expect(data, isNotNull);
      expect(data!.items.map((item) => item.title).toList(), <String>[
        'Alpha',
        comicTitleFallbackForDisplay('comic-b'),
        'Gamma',
      ]);
      expect(comicRepo.findByIdsCalls.length, 1);
      expect(comicRepo.findByIdCalls, 0);
    });
  });

  group('comicDetailSeriesNavProvider', () {
    test(
      'reuses cached series data when comic id changes within series',
      () async {
        await container.read(comicDetailSeriesNavProvider('comic-a').future);
        final ComicDetailSeriesNavSeriesData? cachedSeriesData = container
            .read(comicDetailSeriesNavForSeriesProvider('series-1'))
            .value;

        final ComicDetailSeriesNavResult result = await container.read(
          comicDetailSeriesNavProvider('comic-b').future,
        );

        expect(result, isA<ComicDetailSeriesNavReady>());
        final ComicDetailSeriesNavReady ready =
            result as ComicDetailSeriesNavReady;
        expect(ready.data.currentIndex, 1);
        expect(identical(ready.data.items, cachedSeriesData?.items), isTrue);
        expect(comicRepo.findByIdsCalls.length, 1);
        expect(comicRepo.findByIdCalls, 0);
      },
    );

    test('returns none when reading context has no membership', () async {
      final ComicDetailSeriesNavResult result = await container.read(
        comicDetailSeriesNavProvider('comic-missing').future,
      );
      expect(result, isA<ComicDetailSeriesNavNone>());
    });
  });
}
