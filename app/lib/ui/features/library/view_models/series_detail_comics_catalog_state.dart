import 'package:hentai_library/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';

class SeriesDetailComicsCatalogState {
  const SeriesDetailComicsCatalogState({
    required this.items,
    required this.pagination,
  });

  final List<SeriesComicPageItem> items;
  final LibraryPagination pagination;
}
