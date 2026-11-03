import 'package:hentai_library/features/library_admin/domain/metadata_refresh_port.dart';
import 'package:hentai_library/features/library_admin/domain/metadata_refresh_types.dart';

/// 元数据刷新编排：经 [MetadataRefreshPort] 调用 Rust，并在需要时 bump catalog revision。
class MetadataRefreshUseCase {
  const MetadataRefreshUseCase({
    required this._port,
    required this._onCatalogRevision,
  });

  final MetadataRefreshPort _port;
  final void Function() _onCatalogRevision;

  Future<void> refreshComic(String comicId) async {
    await _port.refreshComic(comicId);
    _onCatalogRevision();
  }

  Future<MetadataRefreshBatchResult> refreshSeries(String seriesId) async {
    final MetadataRefreshBatchResult batch = await _port.refreshSeries(
      seriesId,
    );
    _onCatalogRevision();
    return batch;
  }

  Future<MetadataRefreshBatchResult> refreshLibrary(String libraryId) async {
    final MetadataRefreshBatchResult result = await _port.refreshLibrary(
      libraryId,
    );
    if (!result.skipped) {
      _onCatalogRevision();
    }
    return result;
  }

  void cancelActive() => _port.cancelActive();
}
