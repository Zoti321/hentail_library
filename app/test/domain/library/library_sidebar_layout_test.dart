import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/library/library_sidebar_layout.dart';
import 'package:hentai_library/domain/library/scan_interval.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:test/test.dart';

LocalLibrary _lib(String id, {bool pinned = true, int sidebarOrder = 0}) {
  return (
    libraryId: id,
    kind: 'local',
    rootPath: '/$id',
    name: id,
    enabledFormatGroups: FormatGroup.all,
    username: '',
    allowHttp: false,
    scanOnStartup: false,
    scanInterval: ScanInterval.disabled,
    pinned: pinned,
    sidebarOrder: sidebarOrder,
  );
}

void main() {
  test('split keeps list_libraries encounter order within each group', () {
    final LibrarySidebarSections sections = splitLibrarySidebar(<LocalLibrary>[
      _lib('c', pinned: true, sidebarOrder: 0),
      _lib('a', pinned: true, sidebarOrder: 1),
      _lib('b', pinned: false, sidebarOrder: 0),
    ]);
    expect(
      sections.pinned.map((LocalLibrary l) => l.libraryId).toList(),
      <String>['c', 'a'],
    );
    expect(
      sections.unpinned.map((LocalLibrary l) => l.libraryId).toList(),
      <String>['b'],
    );
  });

  test('encode writes dense orders from the two section lists', () {
    expect(
      encodeLibrarySidebarLayout(
        pinned: <LocalLibrary>[_lib('c'), _lib('a')],
        unpinned: <LocalLibrary>[_lib('b')],
      ),
      <LibrarySidebarPlacement>[
        (libraryId: 'c', pinned: true, sidebarOrder: 0),
        (libraryId: 'a', pinned: true, sidebarOrder: 1),
        (libraryId: 'b', pinned: false, sidebarOrder: 0),
      ],
    );
  });

  test('reorder within pinned: B after C', () {
    // rows: 0 pinned-header, 1 A, 2 B, 3 C, 4 unpinned-header, 5 D
    final LibrarySidebarSections next = applyLibrarySidebarReorder(
      pinned: <LocalLibrary>[_lib('A'), _lib('B'), _lib('C')],
      unpinned: <LocalLibrary>[_lib('D')],
      oldIndex: 2,
      newIndex: 4,
    );
    expect(next.pinned.map((LocalLibrary l) => l.libraryId).toList(), <String>[
      'A',
      'C',
      'B',
    ]);
    expect(
      next.unpinned.map((LocalLibrary l) => l.libraryId).toList(),
      <String>['D'],
    );
  });

  test('reorder across sections: C becomes first unpinned', () {
    final LibrarySidebarSections next = applyLibrarySidebarReorder(
      pinned: <LocalLibrary>[_lib('A'), _lib('B'), _lib('C')],
      unpinned: <LocalLibrary>[_lib('D')],
      oldIndex: 3,
      newIndex: 5,
    );
    expect(next.pinned.map((LocalLibrary l) => l.libraryId).toList(), <String>[
      'A',
      'B',
    ]);
    expect(
      next.unpinned.map((LocalLibrary l) => l.libraryId).toList(),
      <String>['C', 'D'],
    );
  });

  test('reorder across sections: D becomes pinned before B', () {
    final LibrarySidebarSections next = applyLibrarySidebarReorder(
      pinned: <LocalLibrary>[_lib('A'), _lib('B'), _lib('C')],
      unpinned: <LocalLibrary>[_lib('D')],
      oldIndex: 5,
      newIndex: 2,
    );
    expect(next.pinned.map((LocalLibrary l) => l.libraryId).toList(), <String>[
      'A',
      'D',
      'B',
      'C',
    ]);
    expect(next.unpinned, isEmpty);
  });

  test('reorder from empty pinned: first unpinned becomes pinned', () {
    // rows: 0 pinned-header, 1 unpinned-header, 2 A, 3 B
    final LibrarySidebarSections next = applyLibrarySidebarReorder(
      pinned: const <LocalLibrary>[],
      unpinned: <LocalLibrary>[_lib('A'), _lib('B')],
      oldIndex: 2,
      newIndex: 1,
    );
    expect(next.pinned.map((LocalLibrary l) => l.libraryId).toList(), <String>[
      'A',
    ]);
    expect(
      next.unpinned.map((LocalLibrary l) => l.libraryId).toList(),
      <String>['B'],
    );
  });

  test('moving a section header is ignored', () {
    final List<LocalLibrary> pinned = <LocalLibrary>[_lib('A')];
    final List<LocalLibrary> unpinned = <LocalLibrary>[_lib('B')];
    final LibrarySidebarSections next = applyLibrarySidebarReorder(
      pinned: pinned,
      unpinned: unpinned,
      oldIndex: 0,
      newIndex: 2,
    );
    expect(next.pinned, pinned);
    expect(next.unpinned, unpinned);
  });

  test('more row hidden when unpinned is empty', () {
    expect(showLibrariesMore(const <LocalLibrary>[]), isFalse);
    expect(showLibrariesMore(<LocalLibrary>[_lib('x', pinned: false)]), isTrue);
  });

  test('reorder menu disabled when there are no libraries', () {
    expect(librariesReorderMenuEnabled(0), isFalse);
    expect(librariesReorderMenuEnabled(1), isTrue);
  });
}
