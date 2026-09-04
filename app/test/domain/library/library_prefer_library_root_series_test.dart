import 'package:hentai_library/domain/library/library_prefer_library_root_series.dart';
import 'package:test/test.dart';

void main() {
  group('LibraryPreferLibraryRootSeries.fromStorage', () {
    test('null defaults to enabled', () {
      expect(LibraryPreferLibraryRootSeries.fromStorage(null), isTrue);
    });

    test('false is preserved', () {
      expect(LibraryPreferLibraryRootSeries.fromStorage(false), isFalse);
    });

    test('true is preserved', () {
      expect(LibraryPreferLibraryRootSeries.fromStorage(true), isTrue);
    });
  });
}
