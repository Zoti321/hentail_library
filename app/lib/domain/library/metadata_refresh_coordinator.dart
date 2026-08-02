import 'package:hentai_library/core/errors/app_exception.dart';
import 'package:hentai_library/data/adapters/metadata_refresh_frb_adapter.dart';
import 'package:hentai_library/domain/library/metadata_refresh_types.dart';

/// Comic / Series 元数据刷新编排：调用 FRB，并在成功后通知 library revision。
class MetadataRefreshCoordinator {
  const MetadataRefreshCoordinator({
    required MetadataRefreshFrbAdapter adapter,
    required void Function() onSucceeded,
    required bool Function() isLibrarySyncRunning,
  }) : _adapter = adapter,
       _onSucceeded = onSucceeded,
       _isLibrarySyncRunning = isLibrarySyncRunning;

  final MetadataRefreshFrbAdapter _adapter;
  final void Function() _onSucceeded;
  final bool Function() _isLibrarySyncRunning;

  Future<void> refreshComic(String comicId) async {
    _ensureNotSyncing();
    await _adapter.refreshComic(comicId);
    _onSucceeded();
  }

  Future<RefreshSeriesResult> refreshSeries(
    String seriesId, {
    void Function(RefreshSeriesProgress progress)? onProgress,
  }) async {
    _ensureNotSyncing();
    final RefreshSeriesResult result = await _adapter.refreshSeries(
      seriesId,
      onProgress: onProgress,
    );
    _onSucceeded();
    return result;
  }

  void _ensureNotSyncing() {
    if (_isLibrarySyncRunning()) {
      throw AppException('库同步进行中，请稍后再试');
    }
  }
}
