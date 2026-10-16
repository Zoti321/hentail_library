import 'package:hentai_library/features/library_browse/domain/author_filter_preference_migration.dart';
import 'package:hentai_library/shared/domain/library/library_metadata_filter_selection.dart';
import 'package:hentai_library/features/library_browse/domain/library_tri_state_pick.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/author.dart';
import 'package:test/test.dart';

void main() {
  test('migrates exact display names to ids and drops unmatched', () {
    final LibraryMetadataFilterSelection selection =
        migrateAuthorFilterPreference(
          includeIds: null,
          excludeIds: null,
          legacyIncludeNames: <String>['Alice', 'Ghost'],
          legacyExcludeNames: <String>['Bob'],
          includeModeName: 'all',
          authors: <Author>[
            Author(id: 1, name: 'Alice'),
            Author(id: 2, name: 'Bob'),
          ],
        );
    expect(selection.includeNames(), <String>{'1'});
    expect(selection.excludeNames(), <String>{'2'});
    expect(selection.includeMode, LibraryMetadataIncludeMode.all);
    expect(selection.pickStateFor('1'), LibraryTriStatePick.include);
  });

  test('prefers already-migrated id lists', () {
    final LibraryMetadataFilterSelection selection =
        migrateAuthorFilterPreference(
          includeIds: <String>['9'],
          excludeIds: <String>['8'],
          legacyIncludeNames: <String>['Alice'],
          legacyExcludeNames: <String>['Bob'],
          includeModeName: null,
          authors: <Author>[Author(id: 1, name: 'Alice')],
        );
    expect(selection.includeNames(), <String>{'9'});
    expect(selection.excludeNames(), <String>{'8'});
  });
}
