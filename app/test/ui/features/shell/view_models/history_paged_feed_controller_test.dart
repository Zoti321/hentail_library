import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/reading_history.dart';
import 'package:hentai_library/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/repositories/reading_history_repository.dart';
import 'package:hentai_library/ui/features/shell/di/deps.dart';
import 'package:hentai_library/ui/features/shell/view_models/history_paged_feed_controller.dart';
import 'package:hentai_library/ui/features/shell/view_models/history_paged_feed_state.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';

class _FakeReadingHistoryRepo implements ReadingHistoryRepository {
  _FakeReadingHistoryRepo(this.pagesByKey);

  final Map<String, List<PagedResult<ReadingHistory>>> pagesByKey;
  final List<PageRequest> requests = <PageRequest>[];
  final List<String?> keywords = <String?>[];
  final StreamController<List<ReadingHistory>> _changesController =
      StreamController<List<ReadingHistory>>.broadcast();
  bool failNextFetch = false;
  Completer<PagedResult<ReadingHistory>>? pageTwoCompleter;

  void emitHistoryChange([List<ReadingHistory> histories = const <ReadingHistory>[]]) {
    _changesController.add(histories);
  }

  @override
  Stream<List<ReadingHistory>> watchAllHistory() => _changesController.stream;

  @override
  Future<PagedResult<ReadingHistory>> fetchHistoryPage(
    PageRequest request, {
    String? keyword,
  }) async {
    requests.add(request);
    keywords.add(keyword);
    if (failNextFetch) {
      failNextFetch = false;
      throw Exception('fetch failed');
    }
    if (request.page == 2 && pageTwoCompleter != null) {
      return pageTwoCompleter!.future;
    }
    final String key = _pageKey(request.page, keyword);
    final List<PagedResult<ReadingHistory>>? pages = pagesByKey[key];
    if (pages == null || pages.isEmpty) {
      return PagedResult<ReadingHistory>(
        items: const <ReadingHistory>[],
        totalCount: 0,
        page: request.page,
        pageSize: request.pageSize,
      );
    }
    return pages.first;
  }

  String _pageKey(int page, String? keyword) {
    return '$page:${keyword ?? ''}';
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

ReadingHistory _history({
  required String comicId,
  required String title,
  required int lastReadTimeMs,
}) {
  return ReadingHistory(
    comicId: comicId,
    title: title,
    lastReadTime: DateTime.fromMillisecondsSinceEpoch(lastReadTimeMs),
    pageIndex: 1,
  );
}

PagedResult<ReadingHistory> _page({
  required int page,
  required List<ReadingHistory> items,
  required int totalCount,
  int pageSize = 2,
}) {
  return PagedResult<ReadingHistory>(
    items: items,
    totalCount: totalCount,
    page: page,
    pageSize: pageSize,
  );
}

void main() {
  late _FakeReadingHistoryRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _FakeReadingHistoryRepo(<String, List<PagedResult<ReadingHistory>>>{
      '1:': <PagedResult<ReadingHistory>>[
        _page(
          page: 1,
          totalCount: 3,
          items: <ReadingHistory>[
            _history(comicId: 'c1', title: 'Alpha', lastReadTimeMs: 3000),
            _history(comicId: 'c2', title: 'Beta', lastReadTimeMs: 2000),
          ],
        ),
      ],
      '2:': <PagedResult<ReadingHistory>>[
        _page(
          page: 2,
          totalCount: 3,
          items: <ReadingHistory>[
            _history(comicId: 'c3', title: 'Gamma', lastReadTimeMs: 1000),
          ],
        ),
      ],
      '1:alpha': <PagedResult<ReadingHistory>>[
        _page(
          page: 1,
          totalCount: 1,
          items: <ReadingHistory>[
            _history(comicId: 'c1', title: 'Alpha', lastReadTimeMs: 3000),
          ],
        ),
      ],
    });
    container = ProviderContainer(
      overrides: <Override>[
        readingHistoryRepoProvider.overrideWith((Ref ref) => repo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  HistoryPagedFeedController notifier() =>
      container.read(historyPagedFeedControllerProvider.notifier);

  HistoryPagedFeedState? state() =>
      container.read(historyPagedFeedControllerProvider).asData?.value;

  test('loads first page on build', () async {
    await container.read(historyPagedFeedControllerProvider.future);

    expect(state()?.items, hasLength(2));
    expect(state()?.totalCount, 3);
    expect(state()?.loadedPage, 1);
    expect(state()?.hasReachedEnd, isFalse);
    expect(repo.requests.single.page, 1);
  });

  test('loadMore appends next page', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    await notifier().loadMore();

    expect(state()?.items, hasLength(3));
    expect(state()?.loadedPage, 2);
    expect(state()?.hasReachedEnd, isTrue);
    expect(repo.requests, hasLength(2));
    expect(repo.requests.last.page, 2);
  });

  test('loadMore is ignored when already at end', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    await notifier().loadMore();
    await notifier().loadMore();

    expect(repo.requests, hasLength(2));
  });

  test('setKeyword reloads filtered first page after debounce', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    notifier().setKeyword('alpha');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await container.read(historyPagedFeedControllerProvider.future);

    expect(state()?.items.single.comicId, 'c1');
    expect(state()?.totalCount, 1);
    expect(repo.keywords.last, 'alpha');
  });

  test('removeItem updates local list and totalCount', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    notifier().removeItem('c1');

    expect(state()?.items.single.comicId, 'c2');
    expect(state()?.totalCount, 2);
  });

  test('clearAllLocal resets feed', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    notifier().clearAllLocal();

    expect(state()?.items, isEmpty);
    expect(state()?.totalCount, 0);
    expect(state()?.hasReachedEnd, isTrue);
  });

  test('silent refresh reloads first page when history stream changes', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    expect(repo.requests, hasLength(1));

    repo.pagesByKey['1:'] = <PagedResult<ReadingHistory>>[
      _page(
        page: 1,
        totalCount: 4,
        items: <ReadingHistory>[
          _history(comicId: 'c9', title: 'Newest', lastReadTimeMs: 9000),
          _history(comicId: 'c1', title: 'Alpha', lastReadTimeMs: 3000),
        ],
      ),
    ];
    repo.emitHistoryChange();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await Future<void>.delayed(Duration.zero);

    expect(state()?.items.first.comicId, 'c9');
    expect(state()?.totalCount, 4);
    expect(state()?.loadedPage, 1);
    expect(repo.requests.length, greaterThanOrEqualTo(2));
    expect(repo.requests.last.page, 1);
  });

  test('silent refresh discards stale loadMore result', () async {
    final Completer<PagedResult<ReadingHistory>> pageTwoCompleter =
        Completer<PagedResult<ReadingHistory>>();
    repo.pageTwoCompleter = pageTwoCompleter;

    await container.read(historyPagedFeedControllerProvider.future);
    final Future<void> loadMoreFuture = notifier().loadMore();

    repo.pagesByKey['1:'] = <PagedResult<ReadingHistory>>[
      _page(
        page: 1,
        totalCount: 4,
        items: <ReadingHistory>[
          _history(comicId: 'c9', title: 'Newest', lastReadTimeMs: 9000),
          _history(comicId: 'c1', title: 'Alpha', lastReadTimeMs: 3000),
        ],
      ),
    ];
    repo.emitHistoryChange();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await Future<void>.delayed(Duration.zero);

    pageTwoCompleter.complete(
      _page(
        page: 2,
        totalCount: 3,
        items: <ReadingHistory>[
          _history(comicId: 'c3', title: 'Gamma', lastReadTimeMs: 1000),
        ],
      ),
    );
    await loadMoreFuture;
    await Future<void>.delayed(Duration.zero);

    expect(state()?.items.first.comicId, 'c9');
    expect(state()?.loadedPage, 1);
    expect(state()?.items, hasLength(2));
  });

  test('silent refresh keeps stale data when fetch fails', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    final HistoryPagedFeedState? before = state();

    repo.failNextFetch = true;
    repo.emitHistoryChange();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    await Future<void>.delayed(Duration.zero);

    expect(state(), equals(before));
  });
}
