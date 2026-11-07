import 'package:hentai_library/features/library_admin/domain/metadata_refresh_types.dart';

/// Domain port for metadata refresh (FRB implementation lives in `data/`).
abstract class MetadataRefreshPort {
  Future<void> refreshComic(String comicId);

  Future<MetadataRefreshBatchResult> refreshSeries(String seriesId);

  Future<MetadataRefreshBatchResult> refreshLibrary(String libraryId);

  void cancelActive();
}
