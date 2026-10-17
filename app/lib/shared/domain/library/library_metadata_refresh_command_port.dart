import 'package:hentai_library/shared/domain/library/metadata_refresh_types.dart';

abstract class LibraryMetadataRefreshCommandPort {
  Future<void> refreshComic({required String comicId, required String title});

  Future<MetadataRefreshBatchResult> refreshSeries({
    required String seriesId,
    required String name,
  });

  void cancel();

  bool isRefreshingSeries(String seriesId);

  bool get running;
}
