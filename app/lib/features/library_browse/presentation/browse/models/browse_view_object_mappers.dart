import 'package:hentai_library/features/comic/domain/comic_browse_list_item.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/comic_browse_view_object.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/series_browse_view_object.dart';
import 'package:hentai_library/features/series/domain/series_browse_list_item.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';

ComicBrowseViewObject comicBrowseViewObjectFromComic(Comic comic) {
  return ComicBrowseListItem(
    comicId: comic.comicId,
    title: comic.title,
    pageCount: comic.pageCount,
    path: comic.path,
  );
}

SeriesBrowseViewObject seriesBrowseViewObjectFromSeries(Series series) {
  return SeriesBrowseListItem(
    id: series.id,
    name: series.name,
    volumeCount: series.items.length,
  );
}
