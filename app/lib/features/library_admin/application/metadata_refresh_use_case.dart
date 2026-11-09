import 'package:hentai_library/features/library_admin/domain/metadata_refresh_port.dart';
import 'package:hentai_library/features/library_admin/domain/metadata_refresh_types.dart';
import 'package:hentai_library/shared/domain/events/events.dart';

/// 元数据刷新编排：经 [MetadataRefreshPort] 调用 Rust，并在写入完成后发布目录变更。
class MetadataRefreshUseCase {
  const MetadataRefreshUseCase({
    required this._port,
    required this._events,
  });

  final MetadataRefreshPort _port;
  final DomainEventPublisher _events;

  Future<void> refreshComic(String comicId) async {
    await _port.refreshComic(comicId);
    _publishChanged();
  }

  Future<MetadataRefreshBatchResult> refreshSeries(String seriesId) async {
    final MetadataRefreshBatchResult batch = await _port.refreshSeries(
      seriesId,
    );
    _publishChanged();
    return batch;
  }

  Future<MetadataRefreshBatchResult> refreshLibrary(String libraryId) async {
    final MetadataRefreshBatchResult result = await _port.refreshLibrary(
      libraryId,
    );
    if (!result.skipped) {
      _publishChanged();
    }
    return result;
  }

  void cancelActive() => _port.cancelActive();

  void _publishChanged() => _events.publish(
    const LibraryCatalogChanged(CatalogChangeSource.metadataRefresh),
  );
}
