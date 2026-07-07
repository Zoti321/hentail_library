import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/library/views/library_page/widgets/library_catalog_grid_animation.dart';

void main() {
  group('nextLibraryCatalogSortFlipAnimationEnabled', () {
    test('sort change enables animation even when suppress also changes', () {
      expect(
        nextLibraryCatalogSortFlipAnimationEnabled(
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
          current: false,
          sortChanged: false,
          suppressChanged: false,
        ),
        isFalse,
      );
    });
  });
}
