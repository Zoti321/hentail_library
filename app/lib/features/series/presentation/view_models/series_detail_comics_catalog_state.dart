import 'package:hentai_library/features/series/domain/series_comic_page_item.dart';
import 'package:hentai_library/shared/ui/catalog/pagination/library_pagination.dart';

class SeriesDetailComicsCatalogState {
  const SeriesDetailComicsCatalogState({
    required this.items,
    required this.pagination,
  });

  final List<SeriesComicPageItem> items;
  final LibraryPagination pagination;
}
