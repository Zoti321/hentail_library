import 'package:hentai_library/data/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/domain/library/library_sync_coordinator.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:test/test.dart';

class _RecordingReaderSessionPort implements ReaderSessionPort {
  int clearCount = 0;

  @override
  Future<void> clear() async {
    clearCount++;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _ScriptedSyncAdapter extends SyncLibraryFrbAdapter {
  _ScriptedSyncAdapter(this._run);

  final Future<void> Function({
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  }) _run;

  @override
  Future<void> call({
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  }) {
    return _run(isCancelled: isCancelled, onProgress: onProgress);
  }
}

SyncLibraryProgress _progress({
  required SyncLibraryPhase phase,
  SyncLibraryRoute route = SyncLibraryRoute.withRoots,
}) {
  return (
    phase: phase,
    route: route,
    currentPath: null,
    acceptedTotal: 0,
    counts: emptyLibrarySyncCounts(),
    removedCount: null,
    addedCount: null,
    keptCount: null,
    thumbnailTotal: null,
    thumbnailDone: null,
    thumbnailFailedCount: null,
    errorMessage: null,
  );
}

void main() {
  test('runSync clears reader sessions on thumbnail phase', () async {
    final _RecordingReaderSessionPort sessionPort = _RecordingReaderSessionPort();
    var notifyCount = 0;
    final LibrarySyncCoordinator coordinator = LibrarySyncCoordinator(
      syncAdapter: _ScriptedSyncAdapter(
        ({required isCancelled, onProgress}) async {
          onProgress?.call(
            _progress(phase: SyncLibraryPhase.generatingThumbnails),
          );
        },
      ),
      readerSessionPort: sessionPort,
      onSyncSucceeded: () => notifyCount++,
    );

    await coordinator.runSync(isCancelled: () => false);

    expect(sessionPort.clearCount, 1);
    expect(notifyCount, 1);
  });

  test('runSync skips notifyExternalChange when cancelled', () async {
    var notifyCount = 0;
    final LibrarySyncCoordinator coordinator = LibrarySyncCoordinator(
      syncAdapter: _ScriptedSyncAdapter(
        ({required isCancelled, onProgress}) async {},
      ),
      readerSessionPort: _RecordingReaderSessionPort(),
      onSyncSucceeded: () => notifyCount++,
    );

    await coordinator.runSync(isCancelled: () => true);

    expect(notifyCount, 0);
  });

  test('runSync does not clear sessions for noRootsNoop done route', () async {
    final _RecordingReaderSessionPort sessionPort = _RecordingReaderSessionPort();
    final LibrarySyncCoordinator coordinator = LibrarySyncCoordinator(
      syncAdapter: _ScriptedSyncAdapter(
        ({required isCancelled, onProgress}) async {
          onProgress?.call(
            _progress(
              phase: SyncLibraryPhase.done,
              route: SyncLibraryRoute.noRootsNoop,
            ),
          );
        },
      ),
      readerSessionPort: sessionPort,
      onSyncSucceeded: () {},
    );

    await coordinator.runSync(isCancelled: () => false);

    expect(sessionPort.clearCount, 0);
  });
}
