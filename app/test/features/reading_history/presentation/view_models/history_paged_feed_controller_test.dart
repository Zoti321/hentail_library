import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/reading_history/public.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/features/reading_history/domain/reading_history_repository.dart';
import 'package:hentai_library/features/reading_history/presentation/view_models/history_paged_feed_controller.dart';
import 'package:hentai_library/features/reading_history/presentation/view_models/history_paged_feed_state.dart';
import 'package:riverpod/misc.dart' show Override;
import 'package:test/test.dart';
import 'package:logging/logging.dart';

class _FakeReadingHistoryRepo implements ReadingHistoryRepository {
  _FakeReadingHistoryRepo(this.pagesByKey);

  final Map<String, List<PagedResult<ReadingHistory>>> pagesByKey;
  final List<PageRequest> requests = <PageRequest>[];
  final List<String?> keywords = <String?>[];
  final StreamController<void> _changesController =
      StreamController<void>.broadcast();
  bool failNextFetch = false;
  Completer<PagedResult<ReadingHistory>>? pageTwoCompleter;
  final pendingPages = <String, Completer<PagedResult<ReadingHistory>>>{};

  void emitHistoryChange() {
    _changesController.add(null);
  }

  @override
  Stream<void> watchHistoryChanges() => _changesController.stream;

  @override
  Future<Map<String, int>> listReadPageIndexes() async => const <String, int>{};

  @override
  Future<PagedResult<ReadingHistory>> fetchHistoryPage(
    PageRequest request, {
    String? keyword,
  }) async {
    requests.add(request);
    keywords.add(keyword);
    final pending = pendingPages[_pageKey(request.page, keyword)];
    if (pending != null) return pending.future;
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

  final List<String> deletedComicIds = <String>[];
  int clearAllCalls = 0;
  bool failNextWrite = false;
  Future<void>? pendingWrite;

  void _maybeFailWrite() {
    if (failNextWrite) {
      failNextWrite = false;
      throw Exception('write failed');
    }
  }

  @override
  Future<void> deleteByComicId(String comicId) async {
    await pendingWrite;
    _maybeFailWrite();
    deletedComicIds.add(comicId);
  }

  @override
  Future<void> clearAllHistory() async {
    await pendingWrite;
    _maybeFailWrite();
    clearAllCalls++;
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
  late ProviderSubscription<AsyncValue<HistoryPagedFeedState>> feedSubscription;
  var disposed = false;

  setUp(() {
    disposed = false;
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
    feedSubscription = container.listen(
      historyPagedFeedControllerProvider,
      (_, _) {},
    );
  });

  tearDown(() {
    if (!disposed) {
      feedSubscription.close();
      container.dispose();
    }
  });

  HistoryPagedFeedController notifier() =>
      container.read(historyPagedFeedControllerProvider.notifier);

  HistoryPagedFeedState? state() =>
      container.read(historyPagedFeedControllerProvider).asData?.value;

  Future<void> searchAlpha() async {
    notifier().setKeyword('alpha');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await container.read(historyPagedFeedControllerProvider.future);
  }

  List<LogRecord> observeErrors() {
    final errors = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen((record) {
      if (record.level >= Level.SEVERE) errors.add(record);
    });
    addTearDown(subscription.cancel);
    return errors;
  }

  for (final clear in [false, true]) {
    Future<void> write() =>
        clear ? notifier().clearAllHistory() : notifier().deleteHistory('c2');

    for (final fail in [false, true]) {
      test(
        'accepted history write retains its result after disposal, clear: $clear, fail: $fail',
        () async {
          await container.read(historyPagedFeedControllerProvider.future);
          final pending = Completer<void>();
          repo.pendingWrite = pending.future;
          final result = write();
          final error = StateError('owner write failed');
          final expectation = fail
              ? expectLater(result, throwsA(same(error)))
              : null;
          feedSubscription.close();
          container.dispose();
          disposed = true;
          if (fail) {
            pending.completeError(error);
          } else {
            pending.complete();
          }
          if (fail) {
            await expectation;
          } else {
            await result;
            expect(clear ? repo.clearAllCalls : repo.deletedComicIds.length, 1);
          }
        },
      );
    }

    test(
      'old history write cannot patch a new search, clear: $clear',
      () async {
        await container.read(historyPagedFeedControllerProvider.future);
        final pending = Completer<void>();
        repo.pendingWrite = pending.future;
        final result = write();
        await searchAlpha();
        final before = state();
        pending.complete();
        await result;
        expect(state(), same(before));
        expect(state()?.totalCount, 1);
        expect(clear ? repo.clearAllCalls : repo.deletedComicIds.length, 1);
      },
    );

    test(
      'successful history write invalidates pending pagination, clear: $clear',
      () async {
        await container.read(historyPagedFeedControllerProvider.future);
        final pending = Completer<PagedResult<ReadingHistory>>();
        repo.pendingPages['2:'] = pending;
        final loading = notifier().loadMore();
        await write();
        expect(state()?.isLoadingMore, isFalse);
        pending.complete(repo.pagesByKey['2:']!.first);
        await loading;
        expect(
          state()?.items.map((item) => item.comicId),
          clear ? isEmpty : ['c1'],
        );
        expect(state()?.totalCount, clear ? 0 : 2);
      },
    );

    test(
      'successful history write invalidates an active refresh and permits the next revision, clear: $clear',
      () async {
        await container.read(historyPagedFeedControllerProvider.future);
        final pendingWrite = Completer<void>();
        repo.pendingWrite = pendingWrite.future;
        final writing = write();
        final pending = Completer<PagedResult<ReadingHistory>>();
        repo.pendingPages['1:'] = pending;
        repo.emitHistoryChange();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(repo.requests, hasLength(2));
        pendingWrite.complete();
        await writing;
        pending.complete(repo.pagesByKey['1:']!.first);
        await Future<void>.delayed(Duration.zero);
        expect(
          state()?.items.map((item) => item.comicId),
          clear ? isEmpty : ['c1'],
        );
        repo.pendingPages.remove('1:');
        repo.pagesByKey['1:'] = [
          _page(
            page: 1,
            items: [
              _history(comicId: 'new', title: 'New', lastReadTimeMs: 4000),
            ],
            totalCount: 1,
          ),
        ];
        repo.emitHistoryChange();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(repo.requests, hasLength(3));
        expect(state()?.items.single.comicId, 'new');
      },
    );

    test(
      'successful history write supersedes a pending search build, clear: $clear',
      () async {
        await container.read(historyPagedFeedControllerProvider.future);
        final pending = Completer<PagedResult<ReadingHistory>>();
        repo.pendingPages['1:alpha'] = pending;
        notifier().setKeyword('alpha');
        await Future<void>.delayed(const Duration(milliseconds: 350));
        expect(repo.keywords.last, 'alpha');
        expect(
          container.read(historyPagedFeedControllerProvider).isLoading,
          isTrue,
        );
        final oldPage = _page(
          page: 1,
          items: repo.pagesByKey['1:']!.first.items,
          totalCount: 2,
        );
        final committedPage = _page(
          page: 1,
          items: clear ? [] : [repo.pagesByKey['1:alpha']!.first.items.first],
          totalCount: clear ? 0 : 1,
        );
        repo.pendingPages.remove('1:alpha');
        repo.pagesByKey['1:alpha'] = [committedPage];
        await write();
        pending.complete(oldPage);
        await Future<void>.delayed(Duration.zero);
        await container.read(historyPagedFeedControllerProvider.future);
        expect(state()?.keyword, 'alpha');
        expect(
          state()?.items.map((item) => item.comicId),
          clear ? isEmpty : ['c1'],
        );
        expect(state()?.totalCount, clear ? 0 : 1);
      },
    );

    test(
      'failed history write preserves an in-flight page, clear: $clear',
      () async {
        await container.read(historyPagedFeedControllerProvider.future);
        final pending = Completer<PagedResult<ReadingHistory>>();
        repo.pendingPages['2:'] = pending;
        final loading = notifier().loadMore();
        repo.failNextWrite = true;
        await expectLater(write(), throwsException);
        expect(state()?.isLoadingMore, isTrue);
        pending.complete(repo.pagesByKey['2:']!.first);
        await loading;
        expect(state()?.items.map((item) => item.comicId), ['c1', 'c2', 'c3']);
        expect(state()?.isLoadingMore, isFalse);
      },
    );
  }

  test(
    'concurrent deletions in one query retain both local completions',
    () async {
      await container.read(historyPagedFeedControllerProvider.future);
      final pending = Completer<void>();
      repo.pendingWrite = pending.future;
      final first = notifier().deleteHistory('c1');
      final second = notifier().deleteHistory('c2');
      pending.complete();
      await Future.wait([first, second]);
      expect(state()?.items, isEmpty);
      expect(state()?.totalCount, 1);
      expect(repo.deletedComicIds, ['c1', 'c2']);
    },
  );

  test(
    'write completion replays a revision pending behind an old refresh',
    () async {
      await container.read(historyPagedFeedControllerProvider.future);
      final pending = Completer<PagedResult<ReadingHistory>>();
      repo.pendingPages['1:'] = pending;
      repo.emitHistoryChange();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      repo.emitHistoryChange();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(repo.requests, hasLength(2));
      repo.pendingPages.remove('1:');
      final oldPage = repo.pagesByKey['1:']!.first;
      repo.pagesByKey['1:'] = [
        _page(
          page: 1,
          items: [_history(comicId: 'new', title: 'New', lastReadTimeMs: 4000)],
          totalCount: 1,
        ),
      ];
      await notifier().deleteHistory('c2');
      pending.complete(oldPage);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(repo.requests, hasLength(3));
      expect(state()?.items.single.comicId, 'new');
    },
  );

  test(
    'duplicate deletion does not decrement an already updated count',
    () async {
      await container.read(historyPagedFeedControllerProvider.future);
      await notifier().deleteHistory('c2');
      await notifier().deleteHistory('c2');
      expect(state()?.items.single.comicId, 'c1');
      expect(state()?.totalCount, 2);
      expect(repo.deletedComicIds, ['c2', 'c2']);
    },
  );

  test(
    'old refresh completion preserves the new refresh concurrency guard',
    () async {
      await container.read(historyPagedFeedControllerProvider.future);
      final oldRefresh = Completer<PagedResult<ReadingHistory>>();
      repo.pendingPages['1:'] = oldRefresh;
      repo.emitHistoryChange();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      await searchAlpha();

      final newRefresh = Completer<PagedResult<ReadingHistory>>();
      repo.pendingPages['1:alpha'] = newRefresh;
      repo.emitHistoryChange();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(repo.requests, hasLength(4));

      oldRefresh.complete(repo.pagesByKey['1:']!.first);
      await Future<void>.delayed(Duration.zero);
      repo.emitHistoryChange();
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(repo.requests, hasLength(4));

      repo.pendingPages.remove('1:alpha');
      newRefresh.complete(repo.pagesByKey['1:alpha']!.first);
      await Future<void>.delayed(const Duration(milliseconds: 250));
      expect(repo.requests, hasLength(5));
      expect(repo.keywords.skip(2), ['alpha', 'alpha', 'alpha']);
      expect(state()?.items.map((item) => item.comicId), ['c1']);
    },
  );

  for (final fail in [false, true]) {
    test(
      'old silent refresh cannot affect a new keyword, failure: $fail',
      () async {
        await container.read(historyPagedFeedControllerProvider.future);
        final errors = observeErrors();
        final pending = Completer<PagedResult<ReadingHistory>>();
        repo.pendingPages['1:'] = pending;
        repo.emitHistoryChange();
        await Future<void>.delayed(const Duration(milliseconds: 250));
        expect(repo.requests, hasLength(2));
        await searchAlpha();
        if (fail) {
          pending.completeError(StateError('old query'));
        } else {
          pending.complete(repo.pagesByKey['1:']!.first);
        }
        await Future<void>.delayed(Duration.zero);
        expect(state()?.keyword, 'alpha');
        expect(state()?.items.map((item) => item.comicId), ['c1']);
        expect(errors, isEmpty);
      },
    );

    test(
      'old loadMore cannot finish a new keyword pagination, failure: $fail',
      () async {
        await container.read(historyPagedFeedControllerProvider.future);
        final errors = observeErrors();
        final oldPage = Completer<PagedResult<ReadingHistory>>();
        final newPage = Completer<PagedResult<ReadingHistory>>();
        repo.pendingPages['2:'] = oldPage;
        repo.pendingPages['2:alpha'] = newPage;
        repo.pagesByKey['1:alpha'] = [
          _page(
            page: 1,
            items: [repo.pagesByKey['1:alpha']!.first.items.first],
            totalCount: 3,
          ),
        ];
        final oldLoad = notifier().loadMore();
        await searchAlpha();
        final newLoad = notifier().loadMore();
        expect(state()?.isLoadingMore, isTrue);
        if (fail) {
          oldPage.completeError(StateError('old page'));
        } else {
          oldPage.complete(repo.pagesByKey['2:']!.first);
        }
        await oldLoad;
        expect(state()?.keyword, 'alpha');
        expect(state()?.items.map((item) => item.comicId), ['c1']);
        expect(state()?.isLoadingMore, isTrue);
        expect(errors, isEmpty);
        newPage.complete(
          _page(
            page: 2,
            items: [
              _history(
                comicId: 'alpha2',
                title: 'Alpha 2',
                lastReadTimeMs: 1000,
              ),
            ],
            totalCount: 2,
          ),
        );
        await newLoad;
        expect(state()?.items.map((item) => item.comicId), ['c1', 'alpha2']);
        expect(state()?.isLoadingMore, isFalse);
      },
    );

    for (final silent in [false, true]) {
      test(
        'disposed feed ignores pending ${silent ? 'refresh' : 'loadMore'}, failure: $fail',
        () async {
          await container.read(historyPagedFeedControllerProvider.future);
          final errors = observeErrors();
          final pending = Completer<PagedResult<ReadingHistory>>();
          repo.pendingPages[silent ? '1:' : '2:'] = pending;
          Future<void>? load;
          if (silent) {
            repo.emitHistoryChange();
            await Future<void>.delayed(const Duration(milliseconds: 250));
          } else {
            load = notifier().loadMore();
          }
          feedSubscription.close();
          container.dispose();
          disposed = true;
          if (fail) {
            pending.completeError(StateError('disposed query'));
          } else {
            pending.complete(repo.pagesByKey['2:']!.first);
          }
          await load;
          await Future<void>.delayed(Duration.zero);
          expect(errors, isEmpty);
        },
      );
    }
  }

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

  test(
    'loadMore failure clears isLoadingMore and keeps existing items',
    () async {
      await container.read(historyPagedFeedControllerProvider.future);
      final HistoryPagedFeedState? before = state();

      repo.failNextFetch = true;
      await notifier().loadMore();

      expect(state()?.isLoadingMore, isFalse);
      expect(state()?.items, before?.items);
      expect(state()?.loadedPage, before?.loadedPage);
      expect(state()?.hasReachedEnd, isFalse);
    },
  );

  test('setKeyword reloads filtered first page after debounce', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    notifier().setKeyword('alpha');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await container.read(historyPagedFeedControllerProvider.future);

    expect(state()?.items.single.comicId, 'c1');
    expect(state()?.totalCount, 1);
    expect(repo.keywords.last, 'alpha');
  });

  test('setKeyword empty applies immediately without debounce', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    notifier().setKeyword('alpha');
    await Future<void>.delayed(const Duration(milliseconds: 350));
    await container.read(historyPagedFeedControllerProvider.future);
    expect(repo.keywords.last, 'alpha');

    final int beforeClear = repo.keywords.length;
    notifier().setKeyword('');
    await container.read(historyPagedFeedControllerProvider.future);

    expect(repo.keywords.length, greaterThan(beforeClear));
    expect(repo.keywords.last, isNull);
    expect(state()?.items, hasLength(2));
  });

  test(
    'deleteHistory deletes in repository and drops the item locally',
    () async {
      await container.read(historyPagedFeedControllerProvider.future);
      await notifier().deleteHistory('c1');

      expect(repo.deletedComicIds, <String>['c1']);
      expect(state()?.items.single.comicId, 'c2');
      expect(state()?.totalCount, 2);
    },
  );

  test('deleteHistory failure rethrows and keeps the item', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    repo.failNextWrite = true;

    await expectLater(notifier().deleteHistory('c1'), throwsException);
    expect(state()?.items, hasLength(2));
    expect(state()?.totalCount, 3);
  });

  test('clearAllHistory clears repository and resets feed', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    await notifier().clearAllHistory();

    expect(repo.clearAllCalls, 1);
    expect(state()?.items, isEmpty);
    expect(state()?.totalCount, 0);
    expect(state()?.hasReachedEnd, isTrue);
  });

  test('clearAllHistory failure rethrows and keeps the feed', () async {
    await container.read(historyPagedFeedControllerProvider.future);
    repo.failNextWrite = true;

    await expectLater(notifier().clearAllHistory(), throwsException);
    expect(state()?.items, hasLength(2));
  });

  test(
    'silent refresh reloads first page when history stream changes',
    () async {
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
    },
  );

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
