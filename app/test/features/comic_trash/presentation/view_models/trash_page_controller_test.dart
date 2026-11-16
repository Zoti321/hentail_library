import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/comic/domain/comic.dart';
import 'package:hentai_library/features/comic_trash/application/comic_trash_service.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/features/comic_trash/presentation/providers/comic_trash_use_case_provider.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_controller.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/comic_trash_actions.dart';
import 'package:hentai_library/features/comic_trash/presentation/view_models/trash_page_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_revision_state.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/page_request.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:logging/logging.dart';
import 'package:test/test.dart';

TrashedComic _item(String id) {
  final at = DateTime.utc(2026, 11, 13);
  return (
    comic: Comic.restore(
      comicId: id,
      path: '/$id.cbz',
      resourceType: ResourceType.cbz,
      resourceSize: 1,
      createdAt: at,
      lastUpdatedAt: at,
      title: id,
      pageCount: 1,
    ),
    deletedAt: at,
    libraryName: 'Local',
    isRemote: false,
  );
}

PagedResult<TrashedComic> _page(
  List<TrashedComic> items, {
  int page = 1,
  int? totalCount,
}) => PagedResult(
  items: items,
  totalCount: totalCount ?? items.length,
  page: page,
  pageSize: 100,
);

class _Service implements ComicTrashService {
  var items = [_item('a'), _item('b')];
  final pages = <Future<PagedResult<TrashedComic>>>[];
  Future<TrashedComicCounts>? pendingCounts;
  final requests = <PageRequest>[];
  @override
  Future<PagedResult<TrashedComic>> fetchTrashedPage(
    PageRequest request,
  ) async {
    requests.add(request);
    return pages.isEmpty ? _page(items) : await pages.removeAt(0);
  }

  @override
  Future<TrashedComicCounts> countTrashed() async => pendingCounts == null
      ? (total: items.length, local: items.length, remote: 0)
      : await pendingCounts!;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

const _purgeResult = (succeeded: 7, failed: 0, errorSamples: <String>[]);

class _Actions extends ComicTrashActions {
  final pending = Completer<void>();
  // Test fixture exposes observations/configuration, not reactive application state.
  // ignore: riverpod_lint/avoid_public_notifier_properties
  var calls = 0;
  @override
  void build() {}
  Future<void> _write() async {
    calls++;
    await pending.future;
  }

  @override
  Future<void> restore(List<String> comicIds) => _write();
  @override
  Future<int> restoreAll() async {
    await _write();
    return 7;
  }

  @override
  Future<ComicPurgeResult> purge(List<String> comicIds) async {
    await _write();
    return _purgeResult;
  }

  @override
  Future<ComicPurgeResult> purgeAll() async {
    await _write();
    return _purgeResult;
  }
}

void main() {
  late _Service service;
  late ProviderContainer container;
  late _Actions actions;
  var disposed = false;
  setUp(() {
    disposed = false;
    service = _Service();
    actions = _Actions();
    container = ProviderContainer(
      overrides: [
        comicTrashServiceProvider.overrideWithValue(service),
        comicTrashActionsProvider.overrideWith(() => actions),
        libraryRevisionStateProvider.overrideWithValue(
          const LibraryRevisionState(),
        ),
      ],
    );
    final subscription = container.listen(
      trashPageControllerProvider,
      (_, _) {},
    );
    addTearDown(() {
      if (!disposed) {
        subscription.close();
        container.dispose();
      }
    });
  });
  TrashPageController controller() =>
      container.read(trashPageControllerProvider.notifier);
  TrashPageState current() =>
      container.read(trashPageControllerProvider).requireValue;
  Future<void> initialize() async {
    await container.read(trashPageControllerProvider.future);
    controller().toggleSelected('a');
  }

  List<LogRecord> errors() {
    final records = <LogRecord>[];
    final subscription = Logger.root.onRecord.listen((record) {
      if (record.level >= Level.SEVERE) {
        records.add(record);
      }
    });
    addTearDown(subscription.cancel);
    return records;
  }

  Future<void> initializePaged() async {
    await initialize();
    service.pages.add(Future.value(_page(service.items, totalCount: 101)));
    await controller().refresh();
  }

  test(
    'obsolete pagination failure cannot end a newer pagination request',
    () async {
      await initializePaged();
      final records = errors();
      final oldPage = Completer<PagedResult<TrashedComic>>();
      service.pages.add(oldPage.future);
      final oldLoad = controller().loadMore();
      service.pages.add(Future.value(_page(service.items, totalCount: 101)));
      await controller().refresh();
      final newPage = Completer<PagedResult<TrashedComic>>();
      service.pages.add(newPage.future);
      final newLoad = controller().loadMore();
      expect(current().isLoadingMore, isTrue);
      oldPage.completeError(StateError('obsolete page'));
      await oldLoad;
      expect(current().isLoadingMore, isTrue);
      expect(records, isEmpty);
      newPage.complete(_page([_item('new')], page: 2, totalCount: 101));
      await newLoad;
      expect(current().items.last.comic.comicId, 'new');
      expect(current().isLoadingMore, isFalse);
    },
  );

  test(
    'failed refresh releases obsolete pagination and permits another page',
    () async {
      await initializePaged();
      final records = errors();
      final oldPage = Completer<PagedResult<TrashedComic>>();
      service.pages.add(oldPage.future);
      final oldLoad = controller().loadMore();
      final refreshPage = Completer<PagedResult<TrashedComic>>();
      service.pages.add(refreshPage.future);
      final refreshing = controller().refresh();
      expect(current().isLoadingMore, isFalse);
      refreshPage.completeError(StateError('current refresh'));
      await refreshing;
      oldPage.complete(_page([_item('obsolete')], page: 2, totalCount: 101));
      await oldLoad;
      expect(current().isLoadingMore, isFalse);
      expect(records, hasLength(1));
      service.pages.add(
        Future.value(_page([_item('new')], page: 2, totalCount: 101)),
      );
      await controller().loadMore();
      expect(current().items.last.comic.comicId, 'new');
    },
  );

  test(
    'pagination waits for the active refresh and keeps its new first page',
    () async {
      await initializePaged();
      final pending = Completer<PagedResult<TrashedComic>>();
      service.pages.add(pending.future);
      final refreshing = controller().refresh();
      final before = service.requests.length;
      await controller().loadMore();
      expect(service.requests, hasLength(before));
      pending.complete(_page([_item('fresh')], totalCount: 101));
      await refreshing;
      service.pages.add(
        Future.value(_page([_item('next')], page: 2, totalCount: 101)),
      );
      await controller().loadMore();
      expect(current().items.map((item) => item.comic.comicId), [
        'fresh',
        'next',
      ]);
    },
  );

  test('obsolete refresh cleanup cannot release a newer refresh', () async {
    await initializePaged();
    final records = errors();
    final oldPage = Completer<PagedResult<TrashedComic>>();
    final newPage = Completer<PagedResult<TrashedComic>>();
    service.pages.addAll([oldPage.future, newPage.future]);
    final oldRefresh = controller().refresh();
    final newRefresh = controller().refresh();
    oldPage.completeError(StateError('obsolete refresh'));
    await oldRefresh;
    final before = service.requests.length;
    await controller().loadMore();
    expect(service.requests, hasLength(before));
    newPage.complete(_page([_item('fresh')], totalCount: 101));
    await newRefresh;
    service.pages.add(
      Future.value(_page([_item('next')], page: 2, totalCount: 101)),
    );
    await controller().loadMore();
    expect(current().items.map((item) => item.comic.comicId), [
      'fresh',
      'next',
    ]);
    expect(records, isEmpty);
  });

  test(
    'current pagination failure reports once and allows another page',
    () async {
      await initializePaged();
      final records = errors();
      final pending = Completer<PagedResult<TrashedComic>>();
      service.pages.add(pending.future);
      final loading = controller().loadMore();
      pending.completeError(StateError('current page'));
      await loading;
      expect(current().isLoadingMore, isFalse);
      expect(current().selectedIds, {'a'});
      expect(records, hasLength(1));
      service.pages.add(
        Future.value(_page([_item('next')], page: 2, totalCount: 101)),
      );
      await controller().loadMore();
      expect(current().items.last.comic.comicId, 'next');
    },
  );

  for (final fail in [false, true]) {
    for (final rebuild in [false, true]) {
      test(
        'pagination ignores a replaced page: rebuild=$rebuild failure=$fail',
        () async {
          await initializePaged();
          final records = errors();
          final pending = Completer<PagedResult<TrashedComic>>();
          service.pages.add(pending.future);
          final loading = controller().loadMore();
          if (rebuild) {
            service.items = [_item('replacement')];
            container.invalidate(trashPageControllerProvider);
            await container.read(trashPageControllerProvider.future);
          } else {
            container.dispose();
            disposed = true;
          }
          if (fail) {
            pending.completeError(StateError('replaced page'));
          } else {
            pending.complete(
              _page([_item('obsolete')], page: 2, totalCount: 101),
            );
          }
          await loading;
          if (rebuild) {
            expect(current().items.single.comic.comicId, 'replacement');
          }
          expect(records, isEmpty);
        },
      );
    }
  }

  for (final command in ['restore', 'restoreAll', 'purge', 'purgeAll']) {
    Future<Object?> write() => switch (command) {
      'restore' => controller().restore(['a']),
      'restoreAll' => controller().restoreAll(),
      'purge' => controller().purge(['a']),
      _ => controller().purgeAll(),
    };
    final Object expected = command == 'restore'
        ? 1
        : command == 'restoreAll'
        ? 7
        : _purgeResult;
    for (final phase in ['normal', 'edit', 'dispose', 'error']) {
      test(
        'accepted $command preserves its result and selection ownership: $phase',
        () async {
          await initialize();
          final writing = write();
          final error = StateError('owner failed');
          final checked = phase == 'error'
              ? expectLater(writing, throwsA(same(error)))
              : null;
          if (phase == 'edit') {
            controller().toggleSelected('a');
            controller().toggleSelected('b');
          }
          if (phase == 'dispose' || phase == 'error') {
            container.dispose();
            disposed = true;
          }
          if (phase == 'error') {
            actions.pending.completeError(error);
            await checked;
          } else {
            actions.pending.complete();
            expect(await writing, expected);
            if (!disposed) {
              expect(current().selectedIds, phase == 'edit' ? {'b'} : isEmpty);
            }
          }
          expect(actions.calls, 1);
        },
      );
    }
  }

  for (final change in ['change', 'clear', 'exit']) {
    test(
      'refresh preserves selection edits during its page read: $change',
      () async {
        await initialize();
        final pending = Completer<PagedResult<TrashedComic>>();
        service.pages.add(pending.future);
        final refreshing = controller().refresh();
        if (change == 'exit') {
          controller().exitSelection();
        } else {
          controller().toggleSelected('a');
          if (change == 'change') {
            controller().toggleSelected('b');
          }
        }
        pending.complete(_page(service.items));
        await refreshing;
        expect(current().selectedIds, change == 'change' ? {'b'} : isEmpty);
        expect(current().selectionMode, change != 'exit');
      },
    );
  }

  test('refresh preserves edits during count read and removes disappeared selections', () async {
    await initialize();
    final counts = Completer<TrashedComicCounts>();
    service.pendingCounts = counts.future;
    service.items = [_item('b')];
    final refreshing = controller().refresh();
    await Future<void>.delayed(Duration.zero);
    controller().toggleSelected('b');
    counts.complete((total: 1, local: 1, remote: 0));
    await refreshing;
    expect(current().selectedIds, {'b'});
    expect(current().selectedItems.single.comic.comicId, 'b');
    expect(current().counts, (total: 1, local: 1, remote: 0));
  });

  for (final fail in [false, true]) {
    test(
      'older refresh cannot affect a newer refresh: failure=$fail',
      () async {
        await initialize();
        final records = errors();
        final pending = Completer<PagedResult<TrashedComic>>();
        service.pages.add(pending.future);
        final older = controller().refresh();
        service.items = [_item('b')];
        await controller().refresh();
        controller().toggleSelected('b');
        if (fail) {
          pending.completeError(StateError('obsolete refresh'));
        } else {
          pending.complete(_page([_item('a')]));
        }
        await older;
        expect(current().items.single.comic.comicId, 'b');
        expect(current().selectedIds, {'b'});
        expect(records, isEmpty);
      },
    );

    for (final rebuild in [false, true]) {
      test(
        'refresh ignores a replaced page: rebuild=$rebuild failure=$fail',
        () async {
          await initialize();
          final records = errors();
          final pending = Completer<PagedResult<TrashedComic>>();
          service.pages.add(pending.future);
          final refreshing = controller().refresh();
          if (rebuild) {
            service.items = [_item('b')];
            container.invalidate(trashPageControllerProvider);
            await container.read(trashPageControllerProvider.future);
          } else {
            container.dispose();
            disposed = true;
          }
          if (fail) {
            pending.completeError(StateError('replaced refresh'));
          } else {
            pending.complete(_page([_item('a')]));
          }
          await refreshing;
          if (rebuild) {
            expect(current().items.single.comic.comicId, 'b');
          }
          expect(records, isEmpty);
        },
      );
    }
  }
}
