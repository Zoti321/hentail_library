import 'package:hentai_library/features/library_admin/domain/sync_library_port.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';

/// Library sync 编排：可选本地存储授权 → FRB sync → 成功且未取消时 bump catalog revision。
class SyncLibraryUseCase {
  const SyncLibraryUseCase({
    required SyncLibraryPort port,
    required Future<void> Function() ensureLocalFilesystemAccess,
    required void Function() onCatalogRevision,
  }) : _port = port,
       _ensureLocalFilesystemAccess = ensureLocalFilesystemAccess,
       _onCatalogRevision = onCatalogRevision;

  final SyncLibraryPort _port;
  final Future<void> Function() _ensureLocalFilesystemAccess;
  final void Function() _onCatalogRevision;

  Future<void> run({
    ScanMode mode = ScanMode.incremental,
    bool syncAll = false,
    String? targetLibraryId,
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
    bool promptStorageAccess = true,
  }) async {
    if (promptStorageAccess) {
      await _ensureLocalFilesystemAccess();
    }
    if (isCancelled()) {
      return;
    }
    await _port.call(
      scanMode: mode,
      syncAll: syncAll,
      targetLibraryId: targetLibraryId,
      isCancelled: isCancelled,
      onProgress: onProgress,
    );
    if (!isCancelled()) {
      _onCatalogRevision();
    }
  }

  void cancelActive() => _port.cancelActive();
}
