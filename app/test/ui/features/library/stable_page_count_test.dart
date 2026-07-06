import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_state.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';
import 'package:test/test.dart';

LibraryComicsCatalogState _catalog({int comicCount = 42}) {
  return LibraryComicsCatalogState(
    items: const <Comic>[],
    pagination: LibraryPagination(
      page: 1,
      totalPages: 1,
      totalCount: comicCount,
      isLoading: false,
    ),
    filterQuery: '',
    hasReceivedFirstEmit: true,
    isComicTableEmpty: false,
  );
}

int _readComicCount(LibraryComicsCatalogState state) => state.displayedCount;

void main() {
  test('stableCatalogDisplayedCount keeps previous total during reload', () {
    final LibraryComicsCatalogState loaded = _catalog();

    expect(
      stableCatalogDisplayedCount(
        AsyncData<LibraryComicsCatalogState>(loaded),
        readCount: _readComicCount,
      ),
      42,
    );
    expect(
      stableCatalogDisplayedCount(
        const AsyncLoading<LibraryComicsCatalogState>(),
        readCount: _readComicCount,
      ),
      0,
    );
  });
}
