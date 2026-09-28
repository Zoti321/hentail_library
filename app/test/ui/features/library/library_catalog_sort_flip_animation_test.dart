import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_catalog_grid_animation.dart';

const LibraryCatalogGridSuppressAnimationKey _suppressBase =
    LibraryCatalogGridSuppressAnimationKey(
      keyword: '',
      ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
      page: 2,
      pageSize: 50,
    );

void main() {
  group('libraryCatalogGridPageOnlyChanged', () {
    test('page change with same filters returns true', () {
      expect(
        libraryCatalogGridPageOnlyChanged(
          previous: _suppressBase,
          next: const LibraryCatalogGridSuppressAnimationKey(
            keyword: '',
            ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
            page: 3,
            pageSize: 50,
          ),
        ),
        isTrue,
      );
    });

    test('keyword change returns false even when page changes', () {
      expect(
        libraryCatalogGridPageOnlyChanged(
          previous: _suppressBase,
          next: const LibraryCatalogGridSuppressAnimationKey(
            keyword: 'foo',
            ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
            page: 1,
            pageSize: 50,
          ),
        ),
        isFalse,
      );
    });

    test('page size change returns false', () {
      expect(
        libraryCatalogGridPageOnlyChanged(
          previous: _suppressBase,
          next: const LibraryCatalogGridSuppressAnimationKey(
            keyword: '',
            ageRestriction: LibraryAgeRestrictionFilter.unrestricted,
            page: 3,
            pageSize: 100,
          ),
        ),
        isFalse,
      );
    });
  });

  group('libraryCatalogPageTransitionDirection', () {
    test('next page is forward', () {
      expect(
        libraryCatalogPageTransitionDirection(previousPage: 2, nextPage: 3),
        LibraryCatalogPageTransitionDirection.forward,
      );
    });

    test('previous page is backward', () {
      expect(
        libraryCatalogPageTransitionDirection(previousPage: 4, nextPage: 3),
        LibraryCatalogPageTransitionDirection.backward,
      );
    });
  });

  group('nextLibraryCatalogSortFlipAnimationEnabled', () {
    test('user disabled keeps animation off even on sort change', () {
      expect(
        nextLibraryCatalogSortFlipAnimationEnabled(
          userEnabled: false,
          current: false,
          sortChanged: true,
          suppressChanged: false,
        ),
        isFalse,
      );
    });

    test('sort change enables animation even when suppress also changes', () {
      expect(
        nextLibraryCatalogSortFlipAnimationEnabled(
          userEnabled: true,
          current: false,
          sortChanged: true,
          suppressChanged: true,
        ),
        isTrue,
      );
    });

    test('suppress-only change disables animation', () {
      expect(
        nextLibraryCatalogSortFlipAnimationEnabled(
          userEnabled: true,
          current: true,
          sortChanged: false,
          suppressChanged: true,
        ),
        isFalse,
      );
    });

    test('data refresh keeps pending sort animation enabled', () {
      expect(
        nextLibraryCatalogSortFlipAnimationEnabled(
          userEnabled: true,
          current: true,
          sortChanged: false,
          suppressChanged: false,
        ),
        isTrue,
      );
    });

    test('initial load does not enable animation', () {
      expect(
        nextLibraryCatalogSortFlipAnimationEnabled(
          userEnabled: true,
          current: false,
          sortChanged: false,
          suppressChanged: false,
        ),
        isFalse,
      );
    });
  });
}
