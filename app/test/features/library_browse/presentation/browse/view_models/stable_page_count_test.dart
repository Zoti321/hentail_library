import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/models/comic_browse_view_object.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/features/library_browse/presentation/browse/view_models/library_catalog_state.dart';
import 'package:hentai_library/shared/ui/catalog/pagination/library_pagination.dart';
import 'package:test/test.dart';

LibraryComicsCatalogState _catalog({int comicCount = 42}) {
  return LibraryComicsCatalogState(
    items: const <ComicBrowseViewObject>[],
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
  test('stableCatalogSnapshot keeps previous catalog during reload', () {
    final LibraryComicsCatalogState loaded = _catalog();

    expect(
      stableCatalogSnapshot(AsyncData<LibraryComicsCatalogState>(loaded)),
      loaded,
    );
    expect(
      stableCatalogSnapshot(
        // riverpod marks copyWithPrevious @internal; still the supported way
        // to build AsyncLoading that retains prior data for this selector.
        // ignore: invalid_use_of_internal_member
        AsyncLoading<LibraryComicsCatalogState>().copyWithPrevious(
          AsyncData<LibraryComicsCatalogState>(loaded),
        ),
      ),
      loaded,
    );
    expect(
      stableCatalogSnapshot(const AsyncLoading<LibraryComicsCatalogState>()),
      isNull,
    );
  });

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
