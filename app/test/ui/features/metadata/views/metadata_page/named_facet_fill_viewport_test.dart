import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/metadata/views/metadata_page/widgets/named_facet_fill_viewport.dart';

void main() {
  group('namedFacetShouldAutoLoadMore', () {
    test('true when content is not scrollable and more remains', () {
      expect(
        namedFacetShouldAutoLoadMore(
          hasMore: true,
          hasSearchQuery: false,
          isLoading: false,
          isLoadingMore: false,
          hasError: false,
          maxScrollExtent: 0,
          pixels: 0,
        ),
        isTrue,
      );
    });

    test('true when already near bottom and more remains', () {
      expect(
        namedFacetShouldAutoLoadMore(
          hasMore: true,
          hasSearchQuery: false,
          isLoading: false,
          isLoadingMore: false,
          hasError: false,
          maxScrollExtent: 500,
          pixels: 300,
        ),
        isTrue,
      );
    });

    test('false when user can still scroll to the load threshold', () {
      expect(
        namedFacetShouldAutoLoadMore(
          hasMore: true,
          hasSearchQuery: false,
          isLoading: false,
          isLoadingMore: false,
          hasError: false,
          maxScrollExtent: 1000,
          pixels: 100,
        ),
        isFalse,
      );
    });

    test('false while searching, loading, or after an error', () {
      const base = (
        hasMore: true,
        hasSearchQuery: false,
        isLoading: false,
        isLoadingMore: false,
        hasError: false,
        maxScrollExtent: 0.0,
        pixels: 0.0,
      );

      expect(
        namedFacetShouldAutoLoadMore(
          hasMore: base.hasMore,
          hasSearchQuery: true,
          isLoading: base.isLoading,
          isLoadingMore: base.isLoadingMore,
          hasError: base.hasError,
          maxScrollExtent: base.maxScrollExtent,
          pixels: base.pixels,
        ),
        isFalse,
      );
      expect(
        namedFacetShouldAutoLoadMore(
          hasMore: base.hasMore,
          hasSearchQuery: base.hasSearchQuery,
          isLoading: true,
          isLoadingMore: base.isLoadingMore,
          hasError: base.hasError,
          maxScrollExtent: base.maxScrollExtent,
          pixels: base.pixels,
        ),
        isFalse,
      );
      expect(
        namedFacetShouldAutoLoadMore(
          hasMore: base.hasMore,
          hasSearchQuery: base.hasSearchQuery,
          isLoading: base.isLoading,
          isLoadingMore: true,
          hasError: base.hasError,
          maxScrollExtent: base.maxScrollExtent,
          pixels: base.pixels,
        ),
        isFalse,
      );
      expect(
        namedFacetShouldAutoLoadMore(
          hasMore: base.hasMore,
          hasSearchQuery: base.hasSearchQuery,
          isLoading: base.isLoading,
          isLoadingMore: base.isLoadingMore,
          hasError: true,
          maxScrollExtent: base.maxScrollExtent,
          pixels: base.pixels,
        ),
        isFalse,
      );
      expect(
        namedFacetShouldAutoLoadMore(
          hasMore: false,
          hasSearchQuery: base.hasSearchQuery,
          isLoading: base.isLoading,
          isLoadingMore: base.isLoadingMore,
          hasError: base.hasError,
          maxScrollExtent: base.maxScrollExtent,
          pixels: base.pixels,
        ),
        isFalse,
      );
    });
  });
}
