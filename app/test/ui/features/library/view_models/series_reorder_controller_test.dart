import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/series_reorder_controller.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod/misc.dart' show Override;

/// 无外部端口的 revision，避免 [LibraryRevision.build] 订阅 FRB port。
class _ControllableLibraryRevision extends LibraryRevision {
  @override
  LibraryRevisionState build() {
    return const LibraryRevisionState(revision: 1, hasReceivedFirstEmit: true);
  }
}

class _FakeSeriesRepo implements SeriesRepository {
  _FakeSeriesRepo(this.comics, {this.failSetOrder = false});

  final List<Comic> comics;
  final bool failSetOrder;
  List<String>? lastSubmittedComicIds;
  int setOrderCalls = 0;

  @override
  Future<PagedResult<SeriesComicPageItem>> fetchComicsPage({
    required String seriesId,
    required PageRequest request,
  }) async {
    return PagedResult<SeriesComicPageItem>(
      items: comics
          .map(
            (Comic comic) =>
                (comic: comic, sortOrder: 0.0, sortOrderLocked: false),
          )
          .toList(),
      page: request.page,
      pageSize: request.pageSize,
      totalCount: comics.length,
    );
  }

  @override
  Future<void> setSeriesItemsOrder(
    String seriesId,
    List<SeriesItem> orderedItems,
  ) async {
    setOrderCalls += 1;
    lastSubmittedComicIds = orderedItems
        .map((SeriesItem item) => item.comicId)
        .toList();
    if (failSetOrder) {
      throw StateError('persist failed');
    }
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Comic _comic(int index) {
  return Comic(
    comicId: 'comic-$index',
    path: '/comics/$index',
    resourceType: ResourceType.dir,
    resourceSize: 0,
    createdAt: DateTime.utc(2024),
    lastUpdatedAt: DateTime.utc(2024),
    title: 'Comic $index',
    pageCount: 10,
  );
}

ProviderContainer _container(_FakeSeriesRepo repo) {
  final ProviderContainer container = ProviderContainer(
    overrides: <Override>[
      libraryRevisionProvider.overrideWith(_ControllableLibraryRevision.new),
      seriesRepoProvider.overrideWith((Ref ref) => repo),
    ],
  );
  return container;
}

List<String> _ids(List<SeriesComicPageItem> items) =>
    items.map((SeriesComicPageItem item) => item.comic.comicId).toList();

void main() {
  test('build loads all members ordered from the paged fetch', () async {
    final _FakeSeriesRepo repo = _FakeSeriesRepo(<Comic>[
      _comic(1),
      _comic(2),
      _comic(3),
    ]);
    final ProviderContainer container = _container(repo);
    addTearDown(container.dispose);

    final List<SeriesComicPageItem> members = await container.read(
      seriesReorderControllerProvider('series-1').future,
    );

    expect(_ids(members), <String>['comic-1', 'comic-2', 'comic-3']);
  });

  test('reorder submits full ordered comicId list and updates state', () async {
    final _FakeSeriesRepo repo = _FakeSeriesRepo(<Comic>[
      _comic(1),
      _comic(2),
      _comic(3),
    ]);
    final ProviderContainer container = _container(repo);
    addTearDown(container.dispose);

    final List<SeriesComicPageItem> original = await container.read(
      seriesReorderControllerProvider('series-1').future,
    );
    final List<SeriesComicPageItem> reordered = <SeriesComicPageItem>[
      original[2],
      original[0],
      original[1],
    ];

    await container
        .read(seriesReorderControllerProvider('series-1').notifier)
        .reorder(reordered);

    expect(repo.setOrderCalls, 1);
    expect(repo.lastSubmittedComicIds, <String>[
      'comic-3',
      'comic-1',
      'comic-2',
    ]);
    final List<SeriesComicPageItem> current = container
        .read(seriesReorderControllerProvider('series-1'))
        .value!;
    expect(_ids(current), <String>['comic-3', 'comic-1', 'comic-2']);
  });

  test('reorder failure restores the previous visual order', () async {
    final _FakeSeriesRepo repo = _FakeSeriesRepo(<Comic>[
      _comic(1),
      _comic(2),
      _comic(3),
    ], failSetOrder: true);
    final ProviderContainer container = _container(repo);
    addTearDown(container.dispose);

    final List<SeriesComicPageItem> original = await container.read(
      seriesReorderControllerProvider('series-1').future,
    );
    final List<SeriesComicPageItem> reordered = <SeriesComicPageItem>[
      original[2],
      original[0],
      original[1],
    ];

    await expectLater(
      container
          .read(seriesReorderControllerProvider('series-1').notifier)
          .reorder(reordered),
      throwsA(isA<StateError>()),
    );

    final List<SeriesComicPageItem> current = container
        .read(seriesReorderControllerProvider('series-1'))
        .value!;
    expect(_ids(current), <String>['comic-1', 'comic-2', 'comic-3']);
  });
}
