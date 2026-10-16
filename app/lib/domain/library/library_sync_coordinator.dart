import 'package:hentai_library/domain/library/sync_library_port.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';

/// UI-side helper: FRB Library sync + catalog revision bump.
///
/// Write-lock mutual exclusion with Metadata refresh, and reader-session
/// invalidation after DB writes, live in Rust `hentai_core::sync` — not here.
class LibrarySyncCoordinator {
  const LibrarySyncCoordinator({
    required SyncLibraryPort syncAdapter,
    required void Function() onSyncSucceeded,
  }) : _syncAdapter = syncAdapter,
       _onSyncSucceeded = onSyncSucceeded;

  final SyncLibraryPort _syncAdapter;
  final void Function() _onSyncSucceeded;

  Future<void> runSync({
    ScanMode scanMode = ScanMode.incremental,
    bool syncAll = false,
    String? targetLibraryId,
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  }) async {
    await _syncAdapter.call(
      scanMode: scanMode,
      syncAll: syncAll,
      targetLibraryId: targetLibraryId,
      isCancelled: isCancelled,
      onProgress: onProgress,
    );
    if (!isCancelled()) {
      _onSyncSucceeded();
    }
  }

  void cancelActive() {
    _syncAdapter.cancelActive();
  }
}
