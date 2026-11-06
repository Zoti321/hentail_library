import 'package:test/test.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';

void main() {
  group('LibrariesRoutes', () {
    test('redirects /local to all libraries browse', () {
      expect(
        LibrariesRoutes.redirectPath(locationPath: '/local'),
        LibrariesRoutes.all,
      );
    });

    test('redirects bare /libraries to all', () {
      expect(
        LibrariesRoutes.redirectPath(locationPath: LibrariesRoutes.root),
        LibrariesRoutes.all,
      );
    });

    test('libraryIdFromPath parses single-library browse', () {
      expect(LibrariesRoutes.libraryIdFromPath('/libraries/lib-a'), 'lib-a');
      expect(LibrariesRoutes.libraryIdFromPath('/libraries/all'), isNull);
    });
  });

  group('librariesSidebarSelection', () {
    test('all libraries path activates section', () {
      expect(librariesSidebarSelection(path: LibrariesRoutes.all), (
        sectionActive: true,
        activeLibraryId: null,
      ));
    });

    test('library browse path highlights that library', () {
      expect(librariesSidebarSelection(path: '/libraries/lib-a'), (
        sectionActive: false,
        activeLibraryId: 'lib-a',
      ));
    });

    test('comic detail does not imply a library selection', () {
      expect(librariesSidebarSelection(path: '/comic/c1'), (
        sectionActive: false,
        activeLibraryId: null,
      ));
    });
  });

  group('librariesSidebarSelectedLibraryId', () {
    test('home path does not pre-select a library', () {
      expect(librariesSidebarSelectedLibraryId(path: '/home'), '');
    });

    test('library browse path selects that library', () {
      expect(
        librariesSidebarSelectedLibraryId(path: '/libraries/lib-a'),
        'lib-a',
      );
    });
  });

  group('afterLibraryDeleteNavigation', () {
    test('goes to all when no libraries remain', () {
      expect(
        afterLibraryDeleteNavigation(remainingLibraryIds: <String>[]).goPath,
        LibrariesRoutes.all,
      );
    });

    test('goes to first remaining library', () {
      expect(
        afterLibraryDeleteNavigation(
          remainingLibraryIds: <String>['lib-b', 'lib-c'],
        ).goPath,
        LibrariesRoutes.library('lib-b'),
      );
    });
  });
}
