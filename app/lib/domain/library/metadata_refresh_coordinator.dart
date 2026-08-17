import 'package:hentai_library/data/adapters/metadata_refresh_frb_adapter.dart';
import 'package:hentai_library/domain/library/metadata_refresh_types.dart';

/// UI-side helper: FRB Metadata refresh + catalog revision bump.
///
/// Mutual exclusion with Library sync is enforced by Rust `library_lock`.
/// Controllers may still pre-check UI `running` for friendlier errors.
class MetadataRefreshCoordinator {
  const MetadataRefreshCoordinator({
    required MetadataRefreshFrbAdapter adapter,
    required void Function() onSucceeded,
  }) : _adapter = adapter,
       _onSucceeded = onSucceeded;

  final MetadataRefreshFrbAdapter _adapter;
  final void Function() _onSucceeded;

  Future<void> refreshComic(String comicId) async {
    await _adapter.refreshComic(comicId);
    _onSucceeded();
  }

  Future<MetadataRefreshBatchResult> refreshSeries(String seriesId) async {
    final MetadataRefreshBatchResult result = await _adapter.refreshSeries(
      seriesId,
    );
    _onSucceeded();
    return result;
  }

  Future<MetadataRefreshBatchResult> refreshLibrary(String libraryId) async {
    final MetadataRefreshBatchResult result = await _adapter.refreshLibrary(
      libraryId,
    );
    if (!result.skipped) {
      _onSucceeded();
    }
    return result;
  }

  void cancelActive() => _adapter.cancelActive();
}
