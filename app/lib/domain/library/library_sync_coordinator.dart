import 'package:hentai_library/data/adapters/sync_library_frb_adapter.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/domain/ports/reader_session_port.dart';

/// Library sync I/O 与阅读会话 / revision 通知编排。
class LibrarySyncCoordinator {
  const LibrarySyncCoordinator({
    required SyncLibraryFrbAdapter syncAdapter,
    required ReaderSessionPort readerSessionPort,
    required void Function() onSyncSucceeded,
  }) : _syncAdapter = syncAdapter,
       _readerSessionPort = readerSessionPort,
       _onSyncSucceeded = onSyncSucceeded;

  final SyncLibraryFrbAdapter _syncAdapter;
  final ReaderSessionPort _readerSessionPort;
  final void Function() _onSyncSucceeded;

  Future<void> runSync({
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  }) async {
    var clearedSessions = false;
    Future<void>? sessionClearTask;
    await _syncAdapter.call(
      isCancelled: isCancelled,
      onProgress: (SyncLibraryProgress progress) {
        onProgress?.call(progress);
        if (!clearedSessions && _shouldClearReaderSessions(progress)) {
          clearedSessions = true;
          sessionClearTask = _readerSessionPort.clear();
        }
      },
    );
    if (sessionClearTask != null) {
      await sessionClearTask;
    }
    if (!isCancelled()) {
      _onSyncSucceeded();
    }
  }

  void cancelActive() {
    _syncAdapter.cancelActive();
  }

  static bool _shouldClearReaderSessions(SyncLibraryProgress progress) {
    return progress.phase == SyncLibraryPhase.generatingThumbnails ||
        (progress.phase == SyncLibraryPhase.done &&
            progress.route != SyncLibraryRoute.noRootsNoop);
  }
}
