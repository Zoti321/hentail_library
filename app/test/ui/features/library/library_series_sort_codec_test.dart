import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/ui/features/library/view_models/library_series_sort_codec.dart';
import 'package:test/test.dart';

void main() {
  group('decodeLibrarySeriesSortOption', () {
    test('maps legacy title field to name', () {
      final LibrarySeriesSortOption option = decodeLibrarySeriesSortOption(
        'title,true',
      );

      expect(option.field, LibrarySeriesSortField.name);
      expect(option.descending, isTrue);
    });

    test('decodes new series sort fields', () {
      final LibrarySeriesSortOption option = decodeLibrarySeriesSortOption(
        'comicCount,false',
      );

      expect(option.field, LibrarySeriesSortField.comicCount);
      expect(option.descending, isFalse);
    });

    test('decodes random sort field', () {
      final LibrarySeriesSortOption option = decodeLibrarySeriesSortOption(
        'random,true',
      );

      expect(option.field, LibrarySeriesSortField.random);
      expect(option.descending, isTrue);
    });
  });
}
