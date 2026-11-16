import 'package:hentai_library/features/library_admin/domain/library_sidebar_layout.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';

typedef DeleteLibraryCommand = Future<void> Function(String libraryId);
typedef UpdateLibrarySidebarCommand = Future<void> Function(
  List<LibrarySidebarPlacement> placements,
);
typedef SubmitLibraryFormCommand = Future<LibraryFormApplyResult> Function(
  LibraryForm form, {
  LocalLibrary? original,
});
