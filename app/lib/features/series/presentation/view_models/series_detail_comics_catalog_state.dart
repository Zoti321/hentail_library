import 'package:hentai_library/shared/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/features/library_browse/public/catalog/for_comic_and_series.dart';

class SeriesDetailComicsCatalogState {
  const SeriesDetailComicsCatalogState({
    required this.items,
    required this.pagination,
  });

  final List<SeriesComicPageItem> items;
  final LibraryPagination pagination;
}
