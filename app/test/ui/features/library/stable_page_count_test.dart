import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_selectors.dart';
import 'package:hentai_library/ui/features/library/view_models/library_page_snapshot.dart';
import 'package:test/test.dart';

LibraryPageSnapshot _snapshot({int comicCount = 42}) {
  return LibraryPageSnapshot(
    comics: const <Comic>[],
    comicsPagination: LibraryPagination(
      page: 1,
      totalPages: 1,
      totalCount: comicCount,
      isLoading: false,
    ),
    series: const <Series>[],
    seriesPagination: const LibraryPagination(
      page: 1,
      totalPages: 0,
      totalCount: 0,
      isLoading: false,
    ),
    displayedComicCount: comicCount,
    displayedSeriesCount: 0,
    displayTarget: LibraryDisplayTarget.comics,
    filterQuery: '',
    hasReceivedFirstEmit: true,
    isComicTableEmpty: false,
  );
}

int _readComicCount(LibraryPageSnapshot snapshot) => snapshot.displayedComicCount;

void main() {
  test('stableCatalogDisplayedCount keeps previous total during reload', () {
    final LibraryPageSnapshot loaded = _snapshot();

    expect(
      stableCatalogDisplayedCount(
        AsyncData<LibraryPageSnapshot>(loaded),
        readCount: _readComicCount,
      ),
      42,
    );
    expect(
      stableCatalogDisplayedCount(
        const AsyncLoading<LibraryPageSnapshot>(),
        readCount: _readComicCount,
      ),
      0,
    );
  });
}
