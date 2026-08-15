import 'package:hentai_library/domain/models/entity/library/local_library.dart';

/// Sidebar Library row overflow actions (order matters for UX tests).
enum LibrarySidebarOverflowAction {
  scan,
  deepScan,
  refreshMetadataLater,
  editConnection,
  edit,
  delete,
}

/// Builds overflow items for a Library sidebar child row.
///
/// [edit] is always present and immediately above [delete].
/// [editConnection] is Remote-only and sits above [edit].
List<LibrarySidebarOverflowAction> librarySidebarOverflowActions(
  LocalLibrary library,
) {
  return <LibrarySidebarOverflowAction>[
    LibrarySidebarOverflowAction.scan,
    LibrarySidebarOverflowAction.deepScan,
    LibrarySidebarOverflowAction.refreshMetadataLater,
    if (isRemoteLibrary(library)) LibrarySidebarOverflowAction.editConnection,
    LibrarySidebarOverflowAction.edit,
    LibrarySidebarOverflowAction.delete,
  ];
}
