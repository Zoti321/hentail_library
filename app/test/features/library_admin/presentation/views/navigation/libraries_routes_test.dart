import 'package:test/test.dart';
import 'package:hentai_library/core/constants/libraries_routes.dart';

void main() {
  group('LibrariesRoutes', () {
    test('redirects /local to home', () {
      expect(LibrariesRoutes.redirectPath(locationPath: '/local'), '/home');
    });

    test('redirects bare /libraries to home', () {
      expect(
        LibrariesRoutes.redirectPath(locationPath: LibrariesRoutes.root),
        '/home',
      );
    });

    test('redirects legacy /libraries/all to home', () {
      expect(
        LibrariesRoutes.redirectPath(locationPath: LibrariesRoutes.legacyAll),
        '/home',
      );
    });

    test('libraryIdFromPath parses single-library browse', () {
      expect(LibrariesRoutes.libraryIdFromPath('/libraries/lib-a'), 'lib-a');
      expect(LibrariesRoutes.libraryIdFromPath('/libraries/all'), isNull);
    });
  });

  group('librariesSidebarSelection', () {
    test('legacy all path does not activate a library', () {
      expect(librariesSidebarSelection(path: LibrariesRoutes.legacyAll), (
        activeLibraryId: null,
      ));
    });

    test('library browse path highlights that library', () {
      expect(librariesSidebarSelection(path: '/libraries/lib-a'), (
        activeLibraryId: 'lib-a',
      ));
    });

    test('comic detail does not imply a library selection', () {
      expect(librariesSidebarSelection(path: '/comic/c1'), (
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
    test('goes to home when no libraries remain', () {
      expect(
        afterLibraryDeleteNavigation(remainingLibraryIds: <String>[]).goPath,
        '/home',
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
