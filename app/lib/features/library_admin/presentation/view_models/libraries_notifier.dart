import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_sidebar_layout.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/public/di/library_admin_state_providers.dart';
import 'package:hentai_library/features/library_admin/di/library_write.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/library_admin/di/load_libraries.dart';

export 'package:hentai_library/features/library_admin/domain/libraries_state.dart';

part 'libraries_notifier.g.dart';

@Riverpod(keepAlive: true)
class LibrariesNotifier extends _$LibrariesNotifier {
  LibraryRepository get _repo => ref.read(libraryRepoProvider);

  @override
  Future<LibrariesState> build() async {
    return _load();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> updateSidebarLayout(
    List<LibrarySidebarPlacement> placements,
  ) async {
    final List<LocalLibrary> libraries = await _repo.updateSidebarLayout(
      placements,
    );
    state = AsyncData(LibrariesState(libraries: libraries));
  }

  Future<LibraryFormApplyResult> submitLibraryForm(
    LibraryForm form, {
    LocalLibrary? original,
  }) async {
    final LibraryFormApplyResult result = await ref.read(
      submitLibraryFormUseCaseProvider,
    )(form, original: original);
    if (result is LibraryFormApplySucceeded) {
      await refresh();
    }
    return result;
  }

  Future<void> deleteLibrary(String libraryId) async {
    await ref.read(deleteLibraryUseCaseProvider)(libraryId);
    await refresh();
  }

  Future<LibrariesState> _load() => ref.read(loadLibrariesUseCaseProvider)();
}
