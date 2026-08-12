import 'package:hentai_library/data/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/domain/library/library_sync_coordinator.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:test/test.dart';

class _FakeLibraryRepository implements LibraryRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScriptedSyncAdapter extends SyncLibraryFrbAdapter {
  _ScriptedSyncAdapter(this._run)
    : super(libraryRepository: _FakeLibraryRepository());

  final Future<void> Function({
    ScanMode scanMode,
    bool syncAll,
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  })
  _run;

  @override
  Future<void> call({
    ScanMode scanMode = ScanMode.incremental,
    bool syncAll = false,
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  }) {
    return _run(
      scanMode: scanMode,
      syncAll: syncAll,
      isCancelled: isCancelled,
      onProgress: onProgress,
    );
  }
}

void main() {
  test('runSync notifies catalog revision when not cancelled', () async {
    var notifyCount = 0;
    final LibrarySyncCoordinator coordinator = LibrarySyncCoordinator(
      syncAdapter: _ScriptedSyncAdapter(
        ({
          ScanMode scanMode = ScanMode.incremental,
          bool syncAll = false,
          required isCancelled,
          onProgress,
        }) async {},
      ),
      onSyncSucceeded: () => notifyCount++,
    );

    await coordinator.runSync(isCancelled: () => false);

    expect(notifyCount, 1);
  });

  test('runSync skips catalog revision when cancelled', () async {
    var notifyCount = 0;
    final LibrarySyncCoordinator coordinator = LibrarySyncCoordinator(
      syncAdapter: _ScriptedSyncAdapter(
        ({
          ScanMode scanMode = ScanMode.incremental,
          bool syncAll = false,
          required isCancelled,
          onProgress,
        }) async {},
      ),
      onSyncSucceeded: () => notifyCount++,
    );

    await coordinator.runSync(isCancelled: () => true);

    expect(notifyCount, 0);
  });

  test('runSync forwards progress to the UI callback', () async {
    SyncLibraryProgress? seen;
    final LibrarySyncCoordinator coordinator = LibrarySyncCoordinator(
      syncAdapter: _ScriptedSyncAdapter(({
        ScanMode scanMode = ScanMode.incremental,
        bool syncAll = false,
        required isCancelled,
        onProgress,
      }) async {
        onProgress?.call((
          phase: SyncLibraryPhase.done,
          route: SyncLibraryRoute.withRoots,
          currentPath: null,
          acceptedTotal: 1,
          counts: emptyLibrarySyncCounts(),
          removedCount: null,
          addedCount: null,
          keptCount: null,
          migratedCount: null,
          thumbnailTotal: null,
          thumbnailDone: null,
          thumbnailFailedCount: null,
          errorMessage: null,
        ));
      }),
      onSyncSucceeded: () {},
    );

    await coordinator.runSync(
      isCancelled: () => false,
      onProgress: (SyncLibraryProgress progress) => seen = progress,
    );

    expect(seen?.phase, SyncLibraryPhase.done);
    expect(seen?.acceptedTotal, 1);
  });

  test('runSync forwards syncAll to the adapter', () async {
    bool? seenSyncAll;
    final LibrarySyncCoordinator coordinator = LibrarySyncCoordinator(
      syncAdapter: _ScriptedSyncAdapter(({
        ScanMode scanMode = ScanMode.incremental,
        bool syncAll = false,
        required isCancelled,
        onProgress,
      }) async {
        seenSyncAll = syncAll;
      }),
      onSyncSucceeded: () {},
    );

    await coordinator.runSync(syncAll: true, isCancelled: () => false);

    expect(seenSyncAll, isTrue);
  });
}
