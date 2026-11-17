import 'package:hentai_library/features/series/application/persist_series_item_sort_use_case.dart';
import 'package:hentai_library/shared/domain/events/events.dart';
import 'package:hentai_library/features/series/domain/series_repository.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_item_membership.dart';
import 'package:test/test.dart';

/// 模拟 core：`updateSeriesItemSortOrder` 写 order 且自动上锁。
class _LockObservingSeriesRepository implements SeriesRepository {
  bool? sortOrderLocked;
  double? sortOrder;
  int updateSortOrderCalls = 0;
  int setLockCalls = 0;
  Object? failure;

  @override
  Future<void> updateSeriesItemSortOrder({
    required String seriesId,
    required String comicId,
    required double sortOrder,
  }) async {
    updateSortOrderCalls += 1;
    final error = failure;
    if (error != null) throw error;
    this.sortOrder = sortOrder;
    sortOrderLocked = true;
  }

  @override
  Future<void> setSeriesItemSortOrderLocked({
    required String seriesId,
    required String comicId,
    required bool locked,
  }) async {
    setLockCalls += 1;
    final error = failure;
    if (error != null) throw error;
    sortOrderLocked = locked;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RecordingPublisher implements DomainEventPublisher {
  final List<DomainEvent> events = <DomainEvent>[];

  @override
  void publish(DomainEvent event) => events.add(event);
}

void main() {
  const SeriesItemMembership unlockedSeed = (
    seriesId: 'series-1',
    sortOrder: 1.0,
    sortOrderLocked: false,
  );

  group('PersistSeriesItemSortUseCase', () {
    test('order change with draft unlocked leaves member locked', () async {
      final _LockObservingSeriesRepository repo =
          _LockObservingSeriesRepository()..sortOrderLocked = false;

      await PersistSeriesItemSortUseCase(
        repository: repo,
        events: _RecordingPublisher(),
      )(
        comicId: 'comic-1',
        seed: unlockedSeed,
        sortOrder: 1.5,
        draftLocked: false,
      );

      expect(repo.updateSortOrderCalls, 1);
      expect(repo.sortOrder, 1.5);
      expect(repo.sortOrderLocked, isTrue);
      expect(repo.setLockCalls, 0);
    });

    test('order change while already locked stays locked', () async {
      final _LockObservingSeriesRepository repo =
          _LockObservingSeriesRepository()..sortOrderLocked = true;
      const SeriesItemMembership seed = (
        seriesId: 'series-1',
        sortOrder: 2.0,
        sortOrderLocked: true,
      );

      await PersistSeriesItemSortUseCase(
        repository: repo,
        events: _RecordingPublisher(),
      )(comicId: 'comic-1', seed: seed, sortOrder: 2.5, draftLocked: true);

      expect(repo.updateSortOrderCalls, 1);
      expect(repo.sortOrderLocked, isTrue);
      expect(repo.setLockCalls, 0);
    });

    test('lock-only unlock writes unlocked without changing order', () async {
      final _LockObservingSeriesRepository repo =
          _LockObservingSeriesRepository()
            ..sortOrderLocked = true
            ..sortOrder = 3.0;
      const SeriesItemMembership seed = (
        seriesId: 'series-1',
        sortOrder: 3.0,
        sortOrderLocked: true,
      );

      await PersistSeriesItemSortUseCase(
        repository: repo,
        events: _RecordingPublisher(),
      )(comicId: 'comic-1', seed: seed, sortOrder: 3.0, draftLocked: false);

      expect(repo.updateSortOrderCalls, 0);
      expect(repo.setLockCalls, 1);
      expect(repo.sortOrderLocked, isFalse);
      expect(repo.sortOrder, 3.0);
    });

    test('lock-only lock writes locked without changing order', () async {
      final _LockObservingSeriesRepository repo =
          _LockObservingSeriesRepository()..sortOrderLocked = false;

      await PersistSeriesItemSortUseCase(
        repository: repo,
        events: _RecordingPublisher(),
      )(
        comicId: 'comic-1',
        seed: unlockedSeed,
        sortOrder: 1.0,
        draftLocked: true,
      );

      expect(repo.updateSortOrderCalls, 0);
      expect(repo.setLockCalls, 1);
      expect(repo.sortOrderLocked, isTrue);
    });

    test('unchanged order and lock does not write', () async {
      final _LockObservingSeriesRepository repo =
          _LockObservingSeriesRepository()..sortOrderLocked = false;

      final events = _RecordingPublisher();
      final changed =
          await PersistSeriesItemSortUseCase(repository: repo, events: events)(
            comicId: 'comic-1',
            seed: unlockedSeed,
            sortOrder: 1.0,
            draftLocked: false,
          );

      expect(repo.updateSortOrderCalls, 0);
      expect(repo.setLockCalls, 0);
      expect(changed, isFalse);
      expect(events.events, isEmpty);
    });

    for (final orderChanged in <bool>[true, false]) {
      test(
        'publishes only after successful persistence: orderChanged=$orderChanged',
        () async {
          final repo = _LockObservingSeriesRepository();
          final events = _RecordingPublisher();
          final changed =
              await PersistSeriesItemSortUseCase(
                repository: repo,
                events: events,
              )(
                comicId: 'comic-1',
                seed: unlockedSeed,
                sortOrder: orderChanged ? 2.0 : 1.0,
                draftLocked: true,
              );

          expect(changed, isTrue);
          expect(events.events, <Object>[isA<LibraryCatalogChanged>()]);
        },
      );

      test(
        'preserves write failure without event or retry: orderChanged=$orderChanged',
        () async {
          final error = StateError('write');
          final repo = _LockObservingSeriesRepository()..failure = error;
          final events = _RecordingPublisher();
          await expectLater(
            PersistSeriesItemSortUseCase(repository: repo, events: events)(
              comicId: 'comic-1',
              seed: unlockedSeed,
              sortOrder: orderChanged ? 2.0 : 1.0,
              draftLocked: true,
            ),
            throwsA(same(error)),
          );

          expect(repo.updateSortOrderCalls + repo.setLockCalls, 1);
          expect(events.events, isEmpty);
        },
      );
    }
  });
}
