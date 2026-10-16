import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/shared/domain/library/library_age_restriction_filter.dart';
import 'package:hentai_library/features/library_browse/presentation/views/library_page/widgets/library_catalog_grid_animation.dart';

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
}
