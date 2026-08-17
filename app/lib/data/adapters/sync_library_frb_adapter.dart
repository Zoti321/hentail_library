import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/adapters/frb_error_mapper.dart';
import 'package:hentai_library/domain/library/sync_library_types.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/sync.dart' as rust;

/// Library sync 经 Rust FRB 执行；Dart 负责凭证注入与进度映射。
class SyncLibraryFrbAdapter {
  SyncLibraryFrbAdapter({required LibraryRepository libraryRepository})
    : _libraryRepository = libraryRepository;

  final LibraryRepository _libraryRepository;

  rust.SyncHandleDto? _activeHandle;

  Future<void> call({
    ScanMode scanMode = ScanMode.incremental,
    bool syncAll = false,
    String? targetLibraryId,
    required bool Function() isCancelled,
    void Function(SyncLibraryProgress progress)? onProgress,
  }) async {
    final handle = rust.createSyncHandleFrb();
    _activeHandle = handle;
    try {
      final credentials = await loadRemoteCredentialsForSync(
        libraryRepository: _libraryRepository,
        syncAll: syncAll,
        targetLibraryId: targetLibraryId,
      );
      await for (final rust.SyncLibraryProgressDto event in guardFrbStream(
        () => rust.syncLibraryFrb(
          handle: handle,
          scanMode: _mapScanMode(scanMode),
          syncAll: syncAll,
          targetLibraryId: targetLibraryId,
          credentials: credentials,
        ),
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

/// 从安全存储读取 Remote 密码，供 core WebDAV Basic 鉴权。
Future<List<rust.RemoteLibraryCredentialDto>> loadRemoteCredentialsForSync({
  required LibraryRepository libraryRepository,
  required bool syncAll,
  String? targetLibraryId,
}) async {
  final List<LocalLibrary> libraries = await libraryRepository.list();
  final String? scopedId =
      targetLibraryId ??
      (syncAll ? null : await libraryRepository.getCurrentId());
  final List<rust.RemoteLibraryCredentialDto> out =
      <rust.RemoteLibraryCredentialDto>[];
  for (final LocalLibrary library in libraries) {
    if (!isRemoteLibrary(library)) {
      continue;
    }
    if (scopedId != null && library.libraryId != scopedId) {
      continue;
    }
    final String? password = await libraryRepository.readRemotePassword(
      library.libraryId,
    );
    if (password == null || password.isEmpty) {
      continue;
    }
    out.add(
      rust.RemoteLibraryCredentialDto(
        libraryId: library.libraryId,
        password: password,
      ),
    );
  }
  return out;
}

rust.SyncScanModeDto _mapScanMode(ScanMode mode) {
  return switch (mode) {
    ScanMode.incremental => rust.SyncScanModeDto.incremental,
    ScanMode.full => rust.SyncScanModeDto.full,
  };
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
    migratedCount: dto.migratedCount,
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
