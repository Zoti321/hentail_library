import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic/public/comic_display_title.dart';
import 'package:hentai_library/features/comic/presentation/view_models/comic_detail_series_nav_provider.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/shared/di/series_reading_context_providers.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/ports/series_reading_context_port.dart';
import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';
import 'package:hentai_library/features/library_admin/presentation/view_models/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';
import 'package:hentai_library/features/comic/public/di/comic_repository_providers.dart';

class _FakeLibraryRevision extends LibraryRevisionNotifier {
  @override
  LibraryRevisionState build() {
    return const LibraryRevisionState(revision: 1, hasReceivedFirstEmit: true);
  }
}

class _FakeReadingContextPort implements SeriesReadingContextPort {
  _FakeReadingContextPort(this.contexts);

  final Map<String, SeriesReadingContext> contexts;
  final List<String> requestedComicIds = <String>[];

  @override
  Future<SeriesReadingContext?> getReadingContextByComicId(
    String comicId,
  ) async {
    requestedComicIds.add(comicId);
    return contexts[comicId];
  }
}

class _FakeComicRepo implements ComicLookupRepository {
  _FakeComicRepo(this._titles);

  final Map<String, String> _titles;
  final List<List<String>> findByIdsCalls = <List<String>>[];
  int findByIdCalls = 0;

  Comic _comic(String comicId, String title) {
    return Comic.restore(
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

const SeriesReadingContext _seriesContext = (
  seriesId: 'series-1',
  seriesName: 'Test Series',
  orderedComicIds: <String>['comic-a', 'comic-b', 'comic-c'],
  currentIndex: 0,
);

void main() {
  late _FakeComicRepo comicRepo;
  late _FakeReadingContextPort contextPort;
  late ProviderContainer container;

  ProviderContainer buildContainer({
    required _FakeComicRepo repo,
    required _FakeReadingContextPort port,
  }) {
    return ProviderContainer(
      overrides: <Override>[
        libraryRevisionProvider.overrideWith(_FakeLibraryRevision.new),
        comicLookupRepositoryProvider.overrideWith((Ref ref) => repo),
        seriesReadingContextPortProvider.overrideWithValue(port),
      ],
    );
  }

  setUp(() {
    comicRepo = _FakeComicRepo(<String, String>{
      'comic-a': 'Alpha',
      'comic-b': 'Beta',
      'comic-c': 'Gamma',
    });
    contextPort = _FakeReadingContextPort(<String, SeriesReadingContext>{
      for (final String id in _seriesContext.orderedComicIds)
        id: (
          seriesId: _seriesContext.seriesId,
          seriesName: _seriesContext.seriesName,
          orderedComicIds: _seriesContext.orderedComicIds,
          currentIndex: _seriesContext.orderedComicIds.indexOf(id),
        ),
    });
    container = buildContainer(repo: comicRepo, port: contextPort);
  });

  tearDown(() {
    container.dispose();
  });

  group('comicDetailSeriesNavProvider', () {
    test('builds nav items from Port facts and comic titles', () async {
      final ComicDetailSeriesNavResult result = await container.read(
        comicDetailSeriesNavProvider('comic-b').future,
      );

      expect(result, isA<ComicDetailSeriesNavReady>());
      final ComicDetailSeriesNavReady ready =
          result as ComicDetailSeriesNavReady;
      expect(ready.data.seriesId, 'series-1');
      expect(ready.data.seriesName, 'Test Series');
      expect(ready.data.currentIndex, 1);
      expect(ready.data.items.map((item) => item.title).toList(), <String>[
        'Alpha',
        'Beta',
        'Gamma',
      ]);
      expect(ready.data.previousItem?.comicId, 'comic-a');
      expect(ready.data.nextItem?.comicId, 'comic-c');
      expect(comicRepo.findByIdsCalls, <List<String>>[
        <String>['comic-a', 'comic-b', 'comic-c'],
      ]);
      expect(contextPort.requestedComicIds, <String>['comic-b']);
    });

    test('uses truncated id fallback for missing comics', () async {
      comicRepo = _FakeComicRepo(<String, String>{
        'comic-a': 'Alpha',
        'comic-c': 'Gamma',
      });
      container.dispose();
      container = buildContainer(repo: comicRepo, port: contextPort);

      final ComicDetailSeriesNavResult result = await container.read(
        comicDetailSeriesNavProvider('comic-a').future,
      );

      final ComicDetailSeriesNavReady ready =
          result as ComicDetailSeriesNavReady;
      expect(ready.data.items.map((item) => item.title).toList(), <String>[
        'Alpha',
        comicTitleFallbackForDisplay('comic-b'),
        'Gamma',
      ]);
    });

    test('returns none when Port has no membership', () async {
      final ComicDetailSeriesNavResult result = await container.read(
        comicDetailSeriesNavProvider('comic-missing').future,
      );
      expect(result, isA<ComicDetailSeriesNavNone>());
    });

    test('returns none when comic id is not in ordered ids', () async {
      contextPort = _FakeReadingContextPort(<String, SeriesReadingContext>{
        'comic-x': (
          seriesId: 'series-1',
          seriesName: 'Test Series',
          orderedComicIds: <String>['comic-a', 'comic-b'],
          currentIndex: 0,
        ),
      });
      container.dispose();
      container = buildContainer(repo: comicRepo, port: contextPort);

      final ComicDetailSeriesNavResult result = await container.read(
        comicDetailSeriesNavProvider('comic-x').future,
      );
      expect(result, isA<ComicDetailSeriesNavNone>());
    });
  });
}
