import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/library_sidebar_layout.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/public/providers/library_admin_state_providers.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/library_write_use_case_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:hentai_library/features/library_admin/presentation/providers/load_libraries_use_case_provider.dart';

export 'package:hentai_library/features/library_admin/domain/libraries_state.dart';

part 'libraries_notifier.g.dart';

Duration? _noAutomaticLibraryRetry(int _, Object _) => null;

@Riverpod(keepAlive: true, retry: _noAutomaticLibraryRetry)
class LibrariesNotifier extends _$LibrariesNotifier {
  LibraryRepository get _repo => ref.read(libraryRepoProvider);
  int _projectionGeneration = 0;
  int _buildGeneration = 0;
  AsyncValue<LibrariesState>? _nextBuild;

  @override
  Future<LibrariesState> build() async {
    final next = _nextBuild;
    _nextBuild = null;
    if (next == null) {
      _buildGeneration++;
    }
    ref.onDispose(() {
      if (_nextBuild == null) {
        _buildGeneration++;
      }
      _projectionGeneration++;
    });
    if (next != null) {
      if (next.hasError) {
        Error.throwWithStackTrace(next.error!, next.stackTrace!);
      }
      return next.requireValue;
    }
    _projectionGeneration++;
    return _load();
  }

  Future<void> refresh() async {
    final generation = ++_projectionGeneration;
    final next = await AsyncValue.guard(_load);
    if (ref.mounted && generation == _projectionGeneration) {
      _applyProjection(next);
    }
  }

  Future<void> updateSidebarLayout(
    List<LibrarySidebarPlacement> placements,
  ) async {
    final generation = ++_projectionGeneration;
    final List<LocalLibrary> libraries = await _repo.updateSidebarLayout(
      placements,
    );
    if (ref.mounted && generation == _projectionGeneration) {
      _applyProjection(AsyncData(LibrariesState(libraries: libraries)));
    }
  }

  Future<LibraryFormApplyResult> submitLibraryForm(
    LibraryForm form, {
    LocalLibrary? original,
  }) async {
    final generation = _buildGeneration;
    final LibraryFormApplyResult result = await ref.read(
      submitLibraryFormUseCaseProvider,
    )(form, original: original);
    if (result is LibraryFormApplySucceeded &&
        ref.mounted &&
        generation == _buildGeneration) {
      await refresh();
    }
    return result;
  }

  Future<void> deleteLibrary(String libraryId) async {
    final generation = _buildGeneration;
    await ref.read(deleteLibraryUseCaseProvider)(libraryId);
    if (ref.mounted && generation == _buildGeneration) {
      await refresh();
    }
  }

  void _applyProjection(AsyncValue<LibrariesState> next) {
    if (state.isLoading) {
      // Reuse the accepted projection instead of rerunning migrations.
      _nextBuild = next;
      ref.invalidateSelf();
    } else {
      state = next;
    }
  }

  Future<LibrariesState> _load() => ref.read(loadLibrariesUseCaseProvider)();
}
