import 'package:hentai_library/features/library_admin/domain/metadata_refresh_types.dart';

typedef RefreshComicMetadataCommand = Future<void> Function({
  required String comicId,
  required String title,
});
typedef RefreshSeriesMetadataCommand =
    Future<MetadataRefreshBatchResult> Function({
      required String seriesId,
      required String name,
    });
typedef RefreshLibraryMetadataCommand =
    Future<MetadataRefreshBatchResult> Function({
      required String libraryId,
      required String name,
    });
typedef CancelMetadataRefreshCommand = void Function();
