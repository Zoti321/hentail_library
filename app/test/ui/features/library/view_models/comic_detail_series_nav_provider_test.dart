import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_detail_series_nav_provider.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:hentai_library/ui/features/shell/state/library_series_providers.dart';
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

  @override
  Future<Comic?> findById(String comicId) async {
    final String? title = _titles[comicId];
    if (title == null) {
      return null;
    }
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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeSeriesRepo implements SeriesRepository {
  _FakeSeriesRepo(this._series);

  final List<Series> _series;

  @override
  Future<List<Series>> getAll() async => _series;

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
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Series _testSeries() {
  return Series(
    id: 'series-1',
    name: 'Test Series',
    folderPath: '/series',
    items: <SeriesItem>[
      SeriesItem(comicId: 'comic-a', order: 0),
      SeriesItem(comicId: 'comic-b', order: 1),
      SeriesItem(comicId: 'comic-c', order: 2),
    ],
  );
}

void main() {
  late Series series;
  late ProviderContainer container;

  setUp(() {
    series = _testSeries();
    container = ProviderContainer(
      overrides: <Override>[
        libraryRevisionProvider.overrideWith(_FakeLibraryRevision.new),
        allSeriesProvider.overrideWith((Ref ref) async => <Series>[series]),
        comicRepoProvider.overrideWith(
          (Ref ref) => _FakeComicRepo(<String, String>{
            'comic-a': 'Alpha',
            'comic-b': 'Beta',
            'comic-c': 'Gamma',
          }),
        ),
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
    });
  });

  group('resolveComicDetailSeriesNavResult', () {
    test('updates current index without rebuilding series items', () async {
      final ComicDetailSeriesNavSeriesData seriesData =
          await container.read(
                comicDetailSeriesNavForSeriesProvider('series-1').future,
              )
              as ComicDetailSeriesNavSeriesData;

      final ComicDetailSeriesNavResult resultA =
          resolveComicDetailSeriesNavResult(
            <Series>[series],
            'comic-a',
            seriesData,
          );
      final ComicDetailSeriesNavResult resultB =
          resolveComicDetailSeriesNavResult(
            <Series>[series],
            'comic-b',
            seriesData,
          );

      expect(resultA, isA<ComicDetailSeriesNavReady>());
      expect(resultB, isA<ComicDetailSeriesNavReady>());
      final ComicDetailSeriesNavReady readyA =
          resultA as ComicDetailSeriesNavReady;
      final ComicDetailSeriesNavReady readyB =
          resultB as ComicDetailSeriesNavReady;
      expect(readyA.data.currentIndex, 0);
      expect(readyB.data.currentIndex, 1);
      expect(identical(readyA.data.items, readyB.data.items), isTrue);
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
      },
    );
  });
}
