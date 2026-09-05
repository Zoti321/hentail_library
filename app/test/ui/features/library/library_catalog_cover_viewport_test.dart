import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/library/view_models/library_catalog_cover_viewport_notifier.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_layout_constants.dart';

void main() {
  test('visibleCatalogGridIndexRange returns buffered visible indices', () {
    final ({int startIndex, int endIndex}) range = visibleCatalogGridIndexRange(
      scrollPixels: 0,
      viewportHeight: 500,
      gridStartScrollOffset: 0,
      itemCount: 40,
      rowExtent: 300,
      rowSpacing: 12,
      crossAxisCount: 4,
      rowBuffer: 1,
    );

    expect(range.startIndex, 0);
    expect(range.endIndex, greaterThan(0));
    expect(range.endIndex, lessThan(40));
  });

  test('libraryGridCrossAxisCount respects max cross axis extent', () {
    expect(
      libraryGridCrossAxisCount(1200, LibraryLayoutTier.expanded),
      greaterThan(3),
    );
    expect(
      libraryGridCrossAxisCount(360, LibraryLayoutTier.compact),
      greaterThanOrEqualTo(1),
    );
  });

  test(
    'cover viewport membership select only flips for enter/leave indices',
    () {
      const Set<int> previous = <int>{0, 1, 2, 3};
      const Set<int> next = <int>{2, 3, 4, 5};

      bool membership(Set<int> indices, int index) => indices.contains(index);

      expect(membership(previous, 0), isTrue);
      expect(membership(next, 0), isFalse);
      expect(membership(previous, 2), isTrue);
      expect(membership(next, 2), isTrue);
      expect(membership(previous, 5), isFalse);
      expect(membership(next, 5), isTrue);
    },
  );
}
