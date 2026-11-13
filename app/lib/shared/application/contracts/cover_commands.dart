import 'package:hentai_library/shared/domain/models/enums.dart';

typedef ComicCoverSetCommand = Future<void> Function({
  required String comicId,
  required String path,
  required ResourceType resourceType,
  required int pageIndex,
});

typedef SeriesCoverSetCommand = Future<void> Function({
  required String seriesId,
  required String comicId,
  required String path,
  required ResourceType resourceType,
  required int pageIndex,
});
