import 'package:hentai_library/shared/domain/library/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';
import 'package:hentai_library/features/library_admin/domain/library_sidebar_layout.dart';
import 'package:hentai_library/shared/domain/models/entity/library/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/value_objects/library_form.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/shared/di/data_providers.dart';
import 'package:hentai_library/features/library_admin/di/library_write.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

export 'package:hentai_library/shared/domain/library/libraries_state.dart';

part 'libraries_notifier.g.dart';

const String _kMigratedResourceFormatCategoriesPref =
    'migrated_enabled_format_groups_to_libraries_v1';
const String _kMigratedAutoScanPref = 'migrated_auto_scan_to_libraries_v1';

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
    final LibraryFormApplyResult result = await ref
        .read(libraryWriteServiceProvider)
        .submitForm(form, original: original);
    if (result is LibraryFormApplySucceeded) {
      await refresh();
    }
    return result;
  }

  Future<void> deleteLibrary(String libraryId) async {
    await ref.read(libraryWriteServiceProvider).deleteLibrary(libraryId);
    await refresh();
  }

  Future<LibrariesState> _load() async {
    await _migrateResourceFormatCategoriesFromLegacyIfNeeded();
    await _migrateAutoScanFromLegacyIfNeeded();
    try {
      await ref.read(appSettingRepoProvider).clearLegacyImportPayload();
    } catch (_) {
      // Best-effort cleanup of staged legacy import keys.
    }
    final List<LocalLibrary> libraries = await _repo.list();
    return LibrariesState(libraries: libraries);
  }

  Future<void> _migrateResourceFormatCategoriesFromLegacyIfNeeded() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kMigratedResourceFormatCategoriesPref) == true) {
        return;
      }
      final List<LocalLibrary> libraries = await _repo.list();
      if (libraries.isEmpty) {
        await prefs.setBool(_kMigratedResourceFormatCategoriesPref, true);
        return;
      }
      final List<ResourceFormatCategory>? legacyGroups = await ref
          .read(appSettingRepoProvider)
          .peekLegacyEnabledResourceFormatCategories();
      final List<ResourceFormatCategory> groups =
          legacyGroups ??
          List<ResourceFormatCategory>.from(ResourceFormatCategory.all);
      for (final LocalLibrary library in libraries) {
        await _repo.updateResourceFormatCategories(
          libraryId: library.libraryId,
          groups: groups,
        );
      }
      await prefs.setBool(_kMigratedResourceFormatCategoriesPref, true);
    } catch (_) {
      // Best-effort upgrade path; browse still works with DB defaults.
    }
  }

  Future<void> _migrateAutoScanFromLegacyIfNeeded() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(_kMigratedAutoScanPref) == true) {
        return;
      }
      final bool? legacy = await ref
          .read(appSettingRepoProvider)
          .peekLegacyAutoScan();
      if (legacy == true) {
        await _repo.setAllScanOnStartup(true);
      }
      await prefs.setBool(_kMigratedAutoScanPref, true);
    } catch (_) {
      // Best-effort; libraries keep scan_on_startup defaults.
    }
  }
}
