import 'package:hentai_library/domain/repositories/series_repository.dart';
import 'package:hentai_library/ui/features/library/view_models/series_item_sort_persist.dart';
import 'package:test/test.dart';

/// 模拟 core：`updateSeriesItemSortOrder` 写 order 且自动上锁。
class _LockObservingSeriesRepository implements SeriesRepository {
  bool? sortOrderLocked;
  double? sortOrder;
  int updateSortOrderCalls = 0;
  int setLockCalls = 0;

  @override
  Future<void> updateSeriesItemSortOrder({
    required String seriesId,
    required String comicId,
    required double sortOrder,
  }) async {
    updateSortOrderCalls += 1;
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
    sortOrderLocked = locked;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const SeriesItemSortEditSeed unlockedSeed = (
    seriesId: 'series-1',
    sortOrder: 1.0,
    sortOrderLocked: false,
  );

  group('persistSeriesItemSortIfChanged', () {
    test('order change with draft unlocked leaves member locked', () async {
      final _LockObservingSeriesRepository repo =
          _LockObservingSeriesRepository()..sortOrderLocked = false;

      await persistSeriesItemSortIfChanged(
        repo: repo,
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
      const SeriesItemSortEditSeed seed = (
        seriesId: 'series-1',
        sortOrder: 2.0,
        sortOrderLocked: true,
      );

      await persistSeriesItemSortIfChanged(
        repo: repo,
        comicId: 'comic-1',
        seed: seed,
        sortOrder: 2.5,
        draftLocked: true,
      );

      expect(repo.updateSortOrderCalls, 1);
      expect(repo.sortOrderLocked, isTrue);
      expect(repo.setLockCalls, 0);
    });

    test('lock-only unlock writes unlocked without changing order', () async {
      final _LockObservingSeriesRepository repo =
          _LockObservingSeriesRepository()
            ..sortOrderLocked = true
            ..sortOrder = 3.0;
      const SeriesItemSortEditSeed seed = (
        seriesId: 'series-1',
        sortOrder: 3.0,
        sortOrderLocked: true,
      );

      await persistSeriesItemSortIfChanged(
        repo: repo,
        comicId: 'comic-1',
        seed: seed,
        sortOrder: 3.0,
        draftLocked: false,
      );

      expect(repo.updateSortOrderCalls, 0);
      expect(repo.setLockCalls, 1);
      expect(repo.sortOrderLocked, isFalse);
      expect(repo.sortOrder, 3.0);
    });

    test('lock-only lock writes locked without changing order', () async {
      final _LockObservingSeriesRepository repo =
          _LockObservingSeriesRepository()..sortOrderLocked = false;

      await persistSeriesItemSortIfChanged(
        repo: repo,
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

      await persistSeriesItemSortIfChanged(
        repo: repo,
        comicId: 'comic-1',
        seed: unlockedSeed,
        sortOrder: 1.0,
        draftLocked: false,
      );

      expect(repo.updateSortOrderCalls, 0);
      expect(repo.setLockCalls, 0);
    });
  });
}
