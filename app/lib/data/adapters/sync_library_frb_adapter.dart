import 'package:hentai_library/domain/ports/reader_session_port.dart';
import 'package:hentai_library/domain/use_cases/sync_library_types.dart';
import 'package:hentai_library/src/rust/api/sync.dart' as rust;

/// Library sync 经 Rust FRB 执行；Dart 仅负责进度映射与阅读会话清理。
class SyncLibraryFrbAdapter {
  SyncLibraryFrbAdapter({required ReaderSessionPort readerSessionPort})
    : _readerSessionPort = readerSessionPort;

  final ReaderSessionPort _readerSessionPort;
  rust.SyncHandleDto? _activeHandle;

  Future<void> call({
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  }) async {
    final handle = rust.createSyncHandleFrb();
    _activeHandle = handle;
    try {
      var clearedSessions = false;
      await for (final rust.SyncLibraryProgressDto event in rust.syncLibraryFrb(
        handle: handle,
      )) {
        if (isCancelled()) {
          rust.cancelSyncFrb(handle: handle);
          return;
        }
        onProgress?.call(mapRustSyncProgress(event));
        if (!clearedSessions &&
            (event.phase == rust.SyncLibraryPhaseDto.generatingThumbnails ||
                (event.phase == rust.SyncLibraryPhaseDto.done &&
                    event.route != rust.SyncLibraryRouteDto.noRootsNoop))) {
          await _readerSessionPort.clear();
          clearedSessions = true;
        }
        if (event.phase == rust.SyncLibraryPhaseDto.done) {
          break;
        }
      }
    } finally {
      _activeHandle = null;
    }
  }

  void cancelActive() {
    final handle = _activeHandle;
    if (handle != null) {
      rust.cancelSyncFrb(handle: handle);
    }
  }
}

SyncLibraryProgress mapRustSyncProgress(rust.SyncLibraryProgressDto dto) {
  return (
    phase: _mapPhase(dto.phase),
    route: _mapRoute(dto.route),
    currentPath: dto.currentPath,
    acceptedTotal: dto.acceptedTotal,
    counts: (
      dir: dto.counts.dir,
      zip: dto.counts.zip,
      cbz: dto.counts.cbz,
      epub: dto.counts.epub,
    ),
    removedCount: dto.removedCount,
    addedCount: dto.addedCount,
    keptCount: dto.keptCount,
    thumbnailTotal: dto.thumbnailTotal,
    thumbnailDone: dto.thumbnailDone,
    thumbnailFailedCount: dto.thumbnailFailedCount,
  );
}

SyncLibraryPhase _mapPhase(rust.SyncLibraryPhaseDto phase) {
  return switch (phase) {
    rust.SyncLibraryPhaseDto.clearingLibrary =>
      SyncLibraryPhase.clearingLibrary,
    rust.SyncLibraryPhaseDto.scanning => SyncLibraryPhase.scanning,
    rust.SyncLibraryPhaseDto.writingDb => SyncLibraryPhase.writingDb,
    rust.SyncLibraryPhaseDto.generatingThumbnails =>
      SyncLibraryPhase.generatingThumbnails,
    rust.SyncLibraryPhaseDto.done => SyncLibraryPhase.done,
  };
}

SyncLibraryRoute _mapRoute(rust.SyncLibraryRouteDto route) {
  return switch (route) {
    rust.SyncLibraryRouteDto.noRootsNoop => SyncLibraryRoute.noRootsNoop,
    rust.SyncLibraryRouteDto.noRootsCleared => SyncLibraryRoute.noRootsCleared,
    rust.SyncLibraryRouteDto.withRoots => SyncLibraryRoute.withRoots,
  };
}
