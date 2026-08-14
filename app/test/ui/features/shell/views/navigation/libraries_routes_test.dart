import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/shell/views/navigation/libraries_routes.dart';

void main() {
  group('LibrariesRoutes.redirectPath', () {
    test('redirects /local to current library browse', () {
      expect(
        LibrariesRoutes.redirectPath(
          locationPath: '/local',
          currentLibraryId: 'lib-a',
        ),
        '/libraries/lib-a',
      );
    });

    test('redirects /local to all when no current library', () {
      expect(
        LibrariesRoutes.redirectPath(
          locationPath: '/local',
          currentLibraryId: null,
        ),
        '/libraries/all',
      );
    });

    test('redirects bare /libraries to all', () {
      expect(
        LibrariesRoutes.redirectPath(
          locationPath: '/libraries',
          currentLibraryId: 'lib-a',
        ),
        '/libraries/all',
      );
    });

    test('leaves other paths alone', () {
      expect(
        LibrariesRoutes.redirectPath(
          locationPath: '/libraries/lib-a',
          currentLibraryId: 'lib-a',
        ),
        isNull,
      );
    });
  });

  group('librariesSidebarSelection', () {
    test('all libraries highlights section only', () {
      expect(
        librariesSidebarSelection(
          path: '/libraries/all',
          currentLibraryId: 'lib-a',
        ),
        (sectionActive: true, activeLibraryId: null),
      );
    });

    test('library browse highlights matching child', () {
      expect(
        librariesSidebarSelection(
          path: '/libraries/lib-b',
          currentLibraryId: 'lib-a',
        ),
        (sectionActive: false, activeLibraryId: 'lib-b'),
      );
    });

    test('comic detail highlights current library child', () {
      expect(
        librariesSidebarSelection(
          path: '/comic/c1',
          currentLibraryId: 'lib-a',
        ),
        (sectionActive: false, activeLibraryId: 'lib-a'),
      );
    });

    test('home highlights neither libraries section nor child', () {
      expect(
        librariesSidebarSelection(path: '/home', currentLibraryId: 'lib-a'),
        (sectionActive: false, activeLibraryId: null),
      );
    });
  });
}
