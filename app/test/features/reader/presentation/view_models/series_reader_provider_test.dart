import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/public/comic.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/features/comic/domain/repositories/comic_lookup_repository.dart';
import 'package:hentai_library/shared/di/series_reading_context_providers.dart';
import 'package:hentai_library/shared/domain/reading/series_reading_context.dart';
import 'package:hentai_library/features/comic/public/comic_display_title.dart';
import 'package:hentai_library/features/reader/presentation/view_models/series_reader_provider.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/features/comic/public/di/comic_repository_providers.dart';
import 'package:hentai_library/features/comic/public/di/comic_read_query.dart';

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
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFindSeriesReadingContextQuery {
  _FakeFindSeriesReadingContextQuery(this._context);

  final SeriesReadingContext? _context;

  Future<SeriesReadingContext?> getReadingContextByComicId(
    String comicId,
  ) async {
    if (_context == null) {
      return null;
    }
    if (!_context.orderedComicIds.contains(comicId)) {
      return null;
    }
    return _context;
  }
}

class _FakeHistoryCommands {
  Future<int?> readResumePageIndex(String comicId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

List<Override> _overrides({
  required _FakeComicRepo comicRepo,
  required SeriesReadingContext? seriesContext,
}) {
  return <Override>[
    comicLookupRepositoryProvider.overrideWith((Ref ref) => comicRepo),
    comicReadQueryProvider.overrideWith(
      (Ref ref) => createComicReadQuery(comicRepo),
    ),
    findSeriesReadingContextQueryProvider.overrideWithValue(
      _FakeFindSeriesReadingContextQuery(seriesContext)
          .getReadingContextByComicId,
    ),
    readResumePageQueryProvider.overrideWith(
      (Ref ref) => _FakeHistoryCommands().readResumePageIndex,
    ),
  ];
}

void main() {
  late _FakeComicRepo comicRepo;
  late ProviderContainer container;

  final SeriesReadingContext seriesContext = (
    seriesId: 'series-1',
    seriesName: 'Test Series',
    orderedComicIds: <String>['comic-a', 'comic-b', 'comic-c'],
    currentIndex: 1,
  );

  setUp(() {
    comicRepo = _FakeComicRepo(<String, String>{
      'comic-a': 'Alpha',
      'comic-b': 'Beta',
      'comic-c': 'Gamma',
    });
    container = ProviderContainer(
      overrides: _overrides(comicRepo: comicRepo, seriesContext: seriesContext),
    );
  });

  tearDown(() {
    container.dispose();
  });

  test(
    'readSessionContextForReader resolves series nav titles with one batch',
    () async {
      final ReadSessionContextData data = await container.read(
        readSessionContextForReaderProvider(comicId: 'comic-b').future,
      );

      expect(data.seriesId, 'series-1');
      expect(data.navContext.currentIndex, 1);
      expect(data.navContext.items.map((item) => item.title).toList(), <String>[
        'Alpha',
        'Beta',
        'Gamma',
      ]);
      expect(comicRepo.findByIdsCalls, <List<String>>[
        <String>['comic-a', 'comic-b', 'comic-c'],
      ]);
      expect(comicRepo.findByIdCalls, 0);
    },
  );

  test('readSessionContextForReader keeps truncated-id fallback for missing members', () async {
    comicRepo = _FakeComicRepo(<String, String>{
      'comic-a': 'Alpha',
      'comic-c': 'Gamma',
    });
    container.dispose();
    container = ProviderContainer(
      overrides: _overrides(comicRepo: comicRepo, seriesContext: seriesContext),
    );

    final ReadSessionContextData data = await container.read(
      readSessionContextForReaderProvider(comicId: 'comic-b').future,
    );

    expect(data.navContext.items.map((item) => item.title).toList(), <String>[
      'Alpha',
      comicTitleFallbackForDisplay('comic-b'),
      'Gamma',
    ]);
    expect(comicRepo.findByIdsCalls.length, 1);
    expect(comicRepo.findByIdCalls, 0);
  });

  test(
    'readSessionContextForReader without series still uses single findById',
    () async {
      container.dispose();
      comicRepo = _FakeComicRepo(<String, String>{'solo': 'Solo Title'});
      container = ProviderContainer(
        overrides: _overrides(comicRepo: comicRepo, seriesContext: null),
      );

      final ReadSessionContextData data = await container.read(
        readSessionContextForReaderProvider(comicId: 'solo').future,
      );

      expect(data.seriesId, isNull);
      expect(data.navContext.items.single.title, 'Solo Title');
      expect(comicRepo.findByIdsCalls, isEmpty);
      expect(comicRepo.findByIdCalls, 1);
    },
  );
}
