import 'package:hentai_library/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/domain/library/library_tri_state_pick.dart';
import 'package:test/test.dart';

void main() {
  group('LibraryTriStatePick', () {
    test('cycles neutral → include → exclude → neutral', () {
      expect(
        LibraryTriStatePick.neutral.next,
        LibraryTriStatePick.include,
      );
      expect(
        LibraryTriStatePick.include.next,
        LibraryTriStatePick.exclude,
      );
      expect(
        LibraryTriStatePick.exclude.next,
        LibraryTriStatePick.neutral,
      );
    });

    test('maps to Checkbox values: unchecked / checked / indeterminate', () {
      expect(LibraryTriStatePick.neutral.checkboxValue, isFalse);
      expect(LibraryTriStatePick.include.checkboxValue, isTrue);
      expect(LibraryTriStatePick.exclude.checkboxValue, isNull);
    });
  });

  group('LibraryMetadataFilterSelection', () {
    test('toggling cycles pick state for a name', () {
      const LibraryMetadataFilterSelection selection =
          LibraryMetadataFilterSelection();
      final LibraryMetadataFilterSelection afterFirst =
          selection.withToggled('百合');
      expect(afterFirst.pickStateFor('百合'), LibraryTriStatePick.include);

      final LibraryMetadataFilterSelection afterSecond =
          afterFirst.withToggled('百合');
      expect(afterSecond.pickStateFor('百合'), LibraryTriStatePick.exclude);

      final LibraryMetadataFilterSelection afterThird =
          afterSecond.withToggled('百合');
      expect(afterThird.pickStateFor('百合'), LibraryTriStatePick.neutral);
    });

    test('include mode all maps include picks to all set', () {
      final LibraryMetadataFilterSelection selection =
          LibraryMetadataFilterSelection(
            picks: <String, LibraryTriStatePick>{
              '百合': LibraryTriStatePick.include,
              '校园': LibraryTriStatePick.include,
              'R18': LibraryTriStatePick.exclude,
            },
            includeMode: LibraryMetadataIncludeMode.all,
          );
      expect(selection.isActive, isTrue);
      expect(selection.includeNames(), <String>{'百合', '校园'});
      expect(selection.excludeNames(), <String>{'R18'});
      expect(
        selection.toFilterSets().all,
        <String>{'百合', '校园'},
      );
      expect(selection.toFilterSets().any, isEmpty);
      expect(selection.toFilterSets().exclude, <String>{'R18'});
    });

    test('include mode any maps include picks to any set', () {
      final LibraryMetadataFilterSelection selection =
          LibraryMetadataFilterSelection(
            picks: <String, LibraryTriStatePick>{
              '百合': LibraryTriStatePick.include,
            },
            includeMode: LibraryMetadataIncludeMode.any,
          );
      expect(selection.toFilterSets().all, isEmpty);
      expect(selection.toFilterSets().any, <String>{'百合'});
    });

    test('storage round-trip preserves picks and include mode', () {
      final LibraryMetadataFilterSelection original =
          LibraryMetadataFilterSelection(
            picks: <String, LibraryTriStatePick>{
              'TagA': LibraryTriStatePick.include,
              'TagB': LibraryTriStatePick.exclude,
            },
            includeMode: LibraryMetadataIncludeMode.all,
          );
      final LibraryMetadataFilterSelection restored =
          LibraryMetadataFilterSelection.fromStorage(
            includeNames: original.includeNames().toList(),
            excludeNames: original.excludeNames().toList(),
            includeModeName: original.includeMode.name,
          );
      expect(restored, original);
    });
  });
}
