import 'package:hentai_library/features/image_set_library/domain/image_set_sync_outcome.dart';
import 'package:hentai_library/features/library_admin/public/contracts.dart';

/// Image set 手动同步：复用 library_admin 的库扫描命令（同一 run 互斥与目录变更事件），
/// 结束后读取投影映射为本 owner 的终态。
class SyncImageSetLibraryUseCase {
  const SyncImageSetLibraryUseCase({
    required this._startScan,
    required this._readSyncState,
  });

  final StartLibraryScanCommand _startScan;
  final LibrarySyncState Function() _readSyncState;

  Future<ImageSetSyncOutcome> call(String libraryId) async {
    await _startScan(targetLibraryId: libraryId, silent: false);
    return imageSetSyncOutcomeFrom(_readSyncState());
  }
}

ImageSetSyncOutcome imageSetSyncOutcomeFrom(LibrarySyncState state) {
  if (state.cancelled) {
    return const ImageSetSyncCancelled();
  }
  final String? error = state.error;
  if (error != null && error.isNotEmpty) {
    return ImageSetSyncFailed(message: error);
  }
  final int added = state.progress?.addedCount ?? 0;
  final int removed = state.progress?.removedCount ?? 0;
  final String? warning = state.progress?.errorMessage;
  if (warning != null && warning.isNotEmpty) {
    return ImageSetSyncWarned(
      message: warning,
      addedCount: added,
      removedCount: removed,
    );
  }
  return ImageSetSyncSucceeded(addedCount: added, removedCount: removed);
}
