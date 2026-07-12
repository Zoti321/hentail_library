import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';

class SeriesDetailComicsCatalogState {
  const SeriesDetailComicsCatalogState({
    required this.items,
    required this.pagination,
  });

  final List<Comic> items;
  final LibraryPagination pagination;
}
