import 'package:hentai_library/features/library_browse/presentation/browse/models/comic_browse_view_object.dart';
import 'package:hentai_library/features/comic/public/comic.dart';

ComicBrowseViewObject comicBrowseViewObjectFromComic(Comic comic) {
  return (
    comicId: comic.comicId,
    title: comic.title,
    pageCount: comic.pageCount,
    path: comic.path,
  );
}
