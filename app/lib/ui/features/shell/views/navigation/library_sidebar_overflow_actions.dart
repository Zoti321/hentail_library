import 'package:hentai_library/domain/models/entity/library/local_library.dart';

/// Sidebar Library row overflow actions (order matters for UX tests).
enum LibrarySidebarOverflowAction {
  scan,
  deepScan,
  refreshMetadataLater,
  edit,
  delete,
}

/// Builds overflow items for a Library sidebar child row.
///
/// [edit] is always present and immediately above [delete].
List<LibrarySidebarOverflowAction> librarySidebarOverflowActions(
  LocalLibrary library,
) {
  return const <LibrarySidebarOverflowAction>[
    LibrarySidebarOverflowAction.scan,
    LibrarySidebarOverflowAction.deepScan,
    LibrarySidebarOverflowAction.refreshMetadataLater,
    LibrarySidebarOverflowAction.edit,
    LibrarySidebarOverflowAction.delete,
  ];
}
