import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/adapters/frb_error_mapper.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/sync.dart' as rust;

/// Library sync 经 Rust FRB 执行；Dart 仅负责进度映射。
class SyncLibraryFrbAdapter {
  SyncLibraryFrbAdapter();

  rust.SyncHandleDto? _activeHandle;

  Future<void> call({
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  }) async {
    final handle = rust.createSyncHandleFrb();
    _activeHandle = handle;
    try {
      await for (final rust.SyncLibraryProgressDto event in guardFrbStream(
        () => rust.syncLibraryFrb(handle: handle),
        fallbackMessage: '漫画库同步失败',
      )) {
        if (isCancelled()) {
          rust.cancelSyncFrb(handle: handle);
          return;
        }
        if (event.phase == rust.SyncLibraryPhaseDto.failed) {
          throw SyncException(event.errorMessage ?? '漫画库同步失败');
        }
        onProgress?.call(mapRustSyncProgress(event));
        if (event.phase == rust.SyncLibraryPhaseDto.done) {
          break;
        }
      }
    } on HentaiErrorDto catch (error, stackTrace) {
      throw mapFrbError(
        error,
        fallbackMessage: '漫画库同步失败',
        stackTrace: stackTrace,
      );
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
      cbr: dto.counts.cbr,
      rar: dto.counts.rar,
      cb7: dto.counts.cb7,
      sevenZ: dto.counts.sevenz,
      pdf: dto.counts.pdf,
    ),
    removedCount: dto.removedCount,
    addedCount: dto.addedCount,
    keptCount: dto.keptCount,
    thumbnailTotal: dto.thumbnailTotal,
    thumbnailDone: dto.thumbnailDone,
    thumbnailFailedCount: dto.thumbnailFailedCount,
    errorMessage: dto.errorMessage,
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
    rust.SyncLibraryPhaseDto.failed => SyncLibraryPhase.failed,
  };
}

SyncLibraryRoute _mapRoute(rust.SyncLibraryRouteDto route) {
  return switch (route) {
    rust.SyncLibraryRouteDto.noRootsNoop => SyncLibraryRoute.noRootsNoop,
    rust.SyncLibraryRouteDto.noRootsCleared => SyncLibraryRoute.noRootsCleared,
    rust.SyncLibraryRouteDto.withRoots => SyncLibraryRoute.withRoots,
  };
}
