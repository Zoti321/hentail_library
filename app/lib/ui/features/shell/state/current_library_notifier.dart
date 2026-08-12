import 'package:hentai_library/domain/library/format_group.dart';
import 'package:hentai_library/domain/models/app_setting.dart';
import 'package:hentai_library/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/domain/repositories/library_repository.dart';
import 'package:hentai_library/ui/features/settings/view_models/settings_notifier.dart';
import 'package:hentai_library/ui/features/shell/di/repos.dart';
import 'package:hentai_library/ui/features/shell/state/library_revision_notifier.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'current_library_notifier.g.dart';

const String _kMigratedFormatGroupsPref =
    'migrated_enabled_format_groups_to_libraries_v1';

class CurrentLibraryState {
  const CurrentLibraryState({
    required this.libraries,
    required this.currentId,
  });

  final List<LocalLibrary> libraries;
  final String? currentId;

  LocalLibrary? get current {
    final String? id = currentId;
    if (id == null) {
      return null;
    }
    for (final LocalLibrary library in libraries) {
      if (library.libraryId == id) {
        return library;
      }
    }
    return null;
  }

  LocalLibrary? findByRootPath(String rootPath) {
    for (final LocalLibrary library in libraries) {
      if (library.rootPath == rootPath) {
        return library;
      }
    }
    return null;
  }

  CurrentLibraryState copyWith({
    List<LocalLibrary>? libraries,
    String? currentId,
    bool clearCurrentId = false,
  }) {
    return CurrentLibraryState(
      libraries: libraries ?? this.libraries,
      currentId: clearCurrentId ? null : (currentId ?? this.currentId),
    );
  }
}

@Riverpod(keepAlive: true)
class CurrentLibraryNotifier extends _$CurrentLibraryNotifier {
  LibraryRepository get _repo => ref.read(libraryRepoProvider);

  @override
  Future<CurrentLibraryState> build() async {
    return _load();
  }

  Future<void> refresh() async {
    state = await AsyncValue.guard(_load);
  }

  Future<void> select(String libraryId) async {
    final CurrentLibraryState? previous = state.asData?.value;
    await _repo.setCurrentId(libraryId);
    ref.read(libraryRevisionProvider.notifier).notifyExternalChange();
    if (previous != null) {
      state = AsyncData(previous.copyWith(currentId: libraryId));
    }
    await refresh();
  }

  Future<CurrentLibraryState> _load() async {
    await _migrateFormatGroupsFromAppSettingIfNeeded();
    final List<LocalLibrary> libraries = await _repo.list();
    final String? currentId = await _repo.getCurrentId();
    return CurrentLibraryState(libraries: libraries, currentId: currentId);
  }

  /// One-shot: copy legacy app-global format groups onto each Local library.
  Future<void> _migrateFormatGroupsFromAppSettingIfNeeded() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kMigratedFormatGroupsPref) == true) {
        return;
      }
      final List<LocalLibrary> libraries = await _repo.list();
      if (libraries.isEmpty) {
        await prefs.setBool(_kMigratedFormatGroupsPref, true);
        return;
      }
      final AppSetting setting = await ref.read(settingsProvider.future);
      final List<FormatGroup> groups = setting.enabledFormatGroups;
      for (final LocalLibrary library in libraries) {
        await _repo.updateFormatGroups(
          libraryId: library.libraryId,
          groups: groups,
        );
      }
      await prefs.setBool(_kMigratedFormatGroupsPref, true);
    } catch (_) {
      // Best-effort upgrade path; browse still works with DB defaults.
    }
  }
}
