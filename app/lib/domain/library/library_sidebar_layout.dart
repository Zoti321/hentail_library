import 'package:hentai_library/domain/models/entity/library/local_library.dart';

typedef LibrarySidebarPlacement = ({
  String libraryId,
  bool pinned,
  int sidebarOrder,
});

typedef LibrarySidebarSections = ({
  List<LocalLibrary> pinned,
  List<LocalLibrary> unpinned,
});

LibrarySidebarSections splitLibrarySidebar(List<LocalLibrary> libraries) {
  return (
    pinned: libraries.where((LocalLibrary library) => library.pinned).toList(),
    unpinned: libraries
        .where((LocalLibrary library) => !library.pinned)
        .toList(),
  );
}

List<LibrarySidebarPlacement> encodeLibrarySidebarLayout({
  required List<LocalLibrary> pinned,
  required List<LocalLibrary> unpinned,
}) {
  return <LibrarySidebarPlacement>[
    for (int i = 0; i < pinned.length; i++)
      (libraryId: pinned[i].libraryId, pinned: true, sidebarOrder: i),
    for (int i = 0; i < unpinned.length; i++)
      (libraryId: unpinned[i].libraryId, pinned: false, sidebarOrder: i),
  ];
}

bool showLibrariesMore(List<LocalLibrary> unpinned) => unpinned.isNotEmpty;

bool librariesReorderMenuEnabled(int libraryCount) => libraryCount > 0;

/// Applies a [ReorderableListView] move over two section headers + library rows.
///
/// Row layout: pinned header, pinned libraries, unpinned header, unpinned libraries.
LibrarySidebarSections applyLibrarySidebarReorder({
  required List<LocalLibrary> pinned,
  required List<LocalLibrary> unpinned,
  required int oldIndex,
  required int newIndex,
}) {
  final List<_SidebarReorderRow> rows = <_SidebarReorderRow>[
    const _SidebarReorderRow.pinnedHeader(),
    for (final LocalLibrary library in pinned)
      _SidebarReorderRow.library(library),
    const _SidebarReorderRow.unpinnedHeader(),
    for (final LocalLibrary library in unpinned)
      _SidebarReorderRow.library(library),
  ];
  if (oldIndex < 0 || oldIndex >= rows.length || rows[oldIndex].isHeader) {
    return (pinned: pinned, unpinned: unpinned);
  }
  int destination = newIndex;
  if (oldIndex < destination) {
    destination -= 1;
  }
  final _SidebarReorderRow moved = rows.removeAt(oldIndex);
  destination = destination.clamp(0, rows.length);
  rows.insert(destination, moved);
  return _sectionsFromRows(rows);
}

LibrarySidebarSections _sectionsFromRows(List<_SidebarReorderRow> rows) {
  final List<LocalLibrary> pinned = <LocalLibrary>[];
  final List<LocalLibrary> unpinned = <LocalLibrary>[];
  var inUnpinned = false;
  for (final _SidebarReorderRow row in rows) {
    if (row.isPinnedHeader) {
      continue;
    }
    if (row.isUnpinnedHeader) {
      inUnpinned = true;
      continue;
    }
    final LocalLibrary? library = row.library;
    if (library == null) {
      continue;
    }
    if (inUnpinned) {
      unpinned.add(library);
    } else {
      pinned.add(library);
    }
  }
  return (pinned: pinned, unpinned: unpinned);
}

class _SidebarReorderRow {
  const _SidebarReorderRow.pinnedHeader()
    : isPinnedHeader = true,
      isUnpinnedHeader = false,
      library = null;

  const _SidebarReorderRow.unpinnedHeader()
    : isPinnedHeader = false,
      isUnpinnedHeader = true,
      library = null;

  const _SidebarReorderRow.library(this.library)
    : isPinnedHeader = false,
      isUnpinnedHeader = false;

  final bool isPinnedHeader;
  final bool isUnpinnedHeader;
  final LocalLibrary? library;

  bool get isHeader => isPinnedHeader || isUnpinnedHeader;
}
