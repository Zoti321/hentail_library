import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/frb_call_guard.dart';
import 'package:hentai_library/data/adapters/frb_error_mapper.dart';
import 'package:hentai_library/data/adapters/remote_credentials_frb.dart';
import 'package:hentai_library/domain/library/metadata_refresh_types.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/src/rust/api/comic.dart' as comic_rust;
import 'package:hentai_library/src/rust/api/init.dart';
import 'package:hentai_library/src/rust/api/series.dart' as series_rust;

/// Metadata refresh 经 Rust FRB 执行。
class MetadataRefreshFrbAdapter {
  const MetadataRefreshFrbAdapter({required LibraryRepository libraryRepository})
    : _libraryRepository = libraryRepository;

  final LibraryRepository _libraryRepository;

  Future<void> refreshComic(String comicId) async {
    await pushRemoteLibraryCredentials(_libraryRepository);
    return guardFrb(
      () => comic_rust.refreshComicMetadataFrb(comicId: comicId),
      fallbackMessage: '刷新元数据失败',
    );
  }

  Future<RefreshSeriesResult> refreshSeries(
    String seriesId, {
    void Function(RefreshSeriesProgress progress)? onProgress,
  }) async {
    await pushRemoteLibraryCredentials(_libraryRepository);
    RefreshSeriesProgress? last;
    try {
      await for (final series_rust.RefreshSeriesProgressFrbDto event
          in guardFrbStream(
            () => series_rust.refreshSeriesMetadataFrb(seriesId: seriesId),
            fallbackMessage: '刷新系列元数据失败',
          )) {
        final RefreshSeriesProgress progress = (
          current: event.current,
          total: event.total,
          comicId: event.comicId,
          succeeded: event.succeeded,
          failed: event.failed,
        );
        last = progress;
        onProgress?.call(progress);
      }
    } on HentaiErrorDto catch (error, stackTrace) {
      throw mapFrbError(
        error,
        fallbackMessage: '刷新系列元数据失败',
        stackTrace: stackTrace,
      );
    }
    if (last == null) {
      throw AppException('刷新系列元数据失败');
    }
    return (succeeded: last.succeeded, failed: last.failed);
  }
}
