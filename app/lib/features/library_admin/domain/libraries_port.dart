import 'package:hentai_library/features/library_admin/domain/library_sidebar_layout.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';

/// Library 列表与生命周期的命令端口。
abstract class LibrariesPort {
  Future<void> deleteLibrary(String libraryId);

  Future<void> updateSidebarLayout(List<LibrarySidebarPlacement> placements);

  Future<LibraryFormApplyResult> submitLibraryForm(
    LibraryForm form, {
    LocalLibrary? original,
  });
}
