import 'package:hentai_library/features/library_admin/domain/sync_library_port.dart';
import 'package:hentai_library/features/library_admin/domain/sync_library_types.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

/// Library sync 编排：可选本地存储授权 → FRB sync → 成功且未取消时发布目录变更。
class SyncLibraryUseCase {
  const SyncLibraryUseCase({
    required this._port,
    required this._ensureLocalFilesystemAccess,
    required this._events,
  });

  final SyncLibraryPort _port;
  final Future<void> Function() _ensureLocalFilesystemAccess;
  final DomainEventPublisher _events;

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
      _events.publish(const LibraryCatalogChanged(CatalogChangeSource.sync));
    }
  }

  void cancelActive() => _port.cancelActive();
}
