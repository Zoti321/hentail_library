import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/adapters/remote_credentials_frb.dart';
import 'package:hentai_library/domain/library/metadata_refresh_types.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as comic_rust;
import 'package:hentai_library/src/rust/api/series.dart' as series_rust;
import 'package:hentai_library/src/rust/api/sync.dart' as sync_rust;

/// Metadata refresh 经 Rust FRB 执行。
class MetadataRefreshFrbAdapter {
  MetadataRefreshFrbAdapter({required LibraryRepository libraryRepository})
    : _libraryRepository = libraryRepository;

  final LibraryRepository _libraryRepository;
  sync_rust.SyncHandleDto? _activeHandle;

  Future<void> refreshComic(String comicId) async {
    await pushRemoteLibraryCredentials(_libraryRepository);
    return guardFrb(
      () => comic_rust.refreshComicMetadataFrb(comicId: comicId),
      fallbackMessage: '刷新元数据失败',
    );
  }

  Future<MetadataRefreshBatchResult> refreshSeries(String seriesId) async {
    await pushRemoteLibraryCredentials(_libraryRepository);
    final sync_rust.SyncHandleDto handle = sync_rust.createSyncHandleFrb();
    _activeHandle = handle;
    try {
      final series_rust.RefreshSeriesResultFrbDto result = await guardFrb(
        () => series_rust.refreshSeriesMetadataFrb(
          seriesId: seriesId,
          handle: handle,
        ),
        fallbackMessage: '刷新系列元数据失败',
      );
      return (
        succeeded: result.succeeded,
        failed: result.failed,
        cancelled: result.cancelled,
        skipped: false,
        skipMessage: null,
      );
    } finally {
      _activeHandle = null;
    }
  }

  Future<MetadataRefreshBatchResult> refreshLibrary(String libraryId) async {
    await pushRemoteLibraryCredentials(_libraryRepository);
    final sync_rust.SyncHandleDto handle = sync_rust.createSyncHandleFrb();
    _activeHandle = handle;
    try {
      final series_rust.RefreshLibraryResultFrbDto result = await guardFrb(
        () => series_rust.refreshLibraryMetadataFrb(
          libraryId: libraryId,
          handle: handle,
        ),
        fallbackMessage: '刷新库元数据失败',
      );
      return (
        succeeded: result.succeeded,
        failed: result.failed,
        cancelled: result.cancelled,
        skipped: result.skipped,
        skipMessage: result.skipMessage,
      );
    } finally {
      _activeHandle = null;
    }
  }

  void cancelActive() {
    final sync_rust.SyncHandleDto? handle = _activeHandle;
    if (handle != null) {
      sync_rust.cancelSyncFrb(handle: handle);
    }
  }
}
