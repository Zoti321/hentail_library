import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/repositories/comic_repository.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/domain/reading/series_reading_context.dart';
import 'package:hentai_library/ui/features/library/view_models/comic_detail_series_nav_provider.dart';
import 'package:hentai_library/ui/features/reader/view_models/series_reader_provider.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

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
  _FakeSeriesRepo(this._context);

  final SeriesReadingContext? _context;

  @override
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

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeHistoryRepo implements ReadingHistoryRepository {
  @override
  Future<ReadingHistory?> getByComicId(String comicId) async => null;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
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
      overrides: <Override>[
        comicRepoProvider.overrideWith((Ref ref) => comicRepo),
        seriesRepoProvider.overrideWith(
          (Ref ref) => _FakeSeriesRepo(seriesContext),
        ),
        readingHistoryRepoProvider.overrideWith(
          (Ref ref) => _FakeHistoryRepo(),
        ),
      ],
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

  test(
    'readSessionContextForReader keeps truncated-id fallback for missing members',
    () async {
      comicRepo = _FakeComicRepo(<String, String>{
        'comic-a': 'Alpha',
        'comic-c': 'Gamma',
      });
      container.dispose();
      container = ProviderContainer(
        overrides: <Override>[
          comicRepoProvider.overrideWith((Ref ref) => comicRepo),
          seriesRepoProvider.overrideWith(
            (Ref ref) => _FakeSeriesRepo(seriesContext),
          ),
          readingHistoryRepoProvider.overrideWith(
            (Ref ref) => _FakeHistoryRepo(),
          ),
        ],
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
    },
  );

  test(
    'readSessionContextForReader without series still uses single findById',
    () async {
      container.dispose();
      comicRepo = _FakeComicRepo(<String, String>{'solo': 'Solo Title'});
      container = ProviderContainer(
        overrides: <Override>[
          comicRepoProvider.overrideWith((Ref ref) => comicRepo),
          seriesRepoProvider.overrideWith((Ref ref) => _FakeSeriesRepo(null)),
          readingHistoryRepoProvider.overrideWith(
            (Ref ref) => _FakeHistoryRepo(),
          ),
        ],
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
