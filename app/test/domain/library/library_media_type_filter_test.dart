import 'package:hentai_library/domain/library/library_media_type_filter.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:test/test.dart';

void main() {
  group('LibraryMediaTypeFilterSelection', () {
    test('empty selection is inactive and shows all resource types', () {
      const LibraryMediaTypeFilterSelection selection =
          LibraryMediaTypeFilterSelection();
      expect(selection.isActive, isFalse);
      expect(selection.comicResourceTypes(), isNull);
    });

    test('partial selection is active and maps resource types', () {
      const LibraryMediaTypeFilterSelection selection =
          LibraryMediaTypeFilterSelection({
            LibraryMediaTypeFilterOption.pdf,
            LibraryMediaTypeFilterOption.epub,
          });
      expect(selection.isActive, isTrue);
      expect(selection.comicResourceTypes(), <ResourceType>{
        ResourceType.pdf,
        ResourceType.epub,
      });
    });

    test('archive option includes all archive resource types', () {
      const LibraryMediaTypeFilterSelection selection =
          LibraryMediaTypeFilterSelection({
            LibraryMediaTypeFilterOption.archive,
          });
      expect(selection.comicResourceTypes(), <ResourceType>{
        ResourceType.zip,
        ResourceType.cbz,
        ResourceType.cbr,
        ResourceType.rar,
        ResourceType.cb7,
        ResourceType.sevenZ,
      });
    });

    test('toggling last selected option clears filter', () {
      const LibraryMediaTypeFilterSelection selection =
          LibraryMediaTypeFilterSelection({LibraryMediaTypeFilterOption.pdf});
      final LibraryMediaTypeFilterSelection cleared = selection.withToggled(
        LibraryMediaTypeFilterOption.pdf,
      );
      expect(cleared.selected, isEmpty);
      expect(cleared.isActive, isFalse);
    });

    test('selecting all options clears filter', () {
      const LibraryMediaTypeFilterSelection selection =
          LibraryMediaTypeFilterSelection({
            LibraryMediaTypeFilterOption.pdf,
            LibraryMediaTypeFilterOption.epub,
          });
      final LibraryMediaTypeFilterSelection cleared = selection.withToggled(
        LibraryMediaTypeFilterOption.archive,
      );
      expect(cleared.selected, isEmpty);
      expect(cleared.comicResourceTypes(), isNull);
    });

    test('fromStorage ignores unknown values', () {
      final LibraryMediaTypeFilterSelection selection =
          LibraryMediaTypeFilterSelection.fromStorage(<String>[
            'pdf',
            'unknown',
            'epub',
          ]);
      expect(selection.selected, <LibraryMediaTypeFilterOption>{
        LibraryMediaTypeFilterOption.pdf,
        LibraryMediaTypeFilterOption.epub,
      });
    });
  });
}
