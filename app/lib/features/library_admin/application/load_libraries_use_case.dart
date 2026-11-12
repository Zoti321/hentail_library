import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';

const String _kMigratedResourceFormatCategoriesPref =
    'migrated_enabled_format_groups_to_libraries_v1';
const String _kMigratedAutoScanPref = 'migrated_auto_scan_to_libraries_v1';

/// 在列表读取前执行旧配置迁移及暂存清理。
///
/// 迁移与清理保留 best-effort 行为，最终列表读取错误继续向上传播。
class LoadLibrariesUseCase {
  const LoadLibrariesUseCase({
    required this.repository,
    required this.readFlag,
    required this.writeFlag,
    required this.peekLegacyResourceFormatPayload,
    required this.peekLegacyAutoScan,
    required this.clearLegacyImportPayload,
  });
  final LibraryRepository repository;
  final Future<bool?> Function(String key) readFlag;
  final Future<void> Function(String key, bool value) writeFlag;
  final Future<({Object? enabledFormatGroups})?> Function()
  peekLegacyResourceFormatPayload;
  final Future<bool?> Function() peekLegacyAutoScan;
  final Future<void> Function() clearLegacyImportPayload;

  Future<LibrariesState> call() async {
    await _migrateResourceFormatCategoriesFromLegacyIfNeeded();
    await _migrateAutoScanFromLegacyIfNeeded();
    try {
      await clearLegacyImportPayload();
    } catch (_) {
      // Best-effort cleanup of staged legacy import keys.
    }
    final List<LocalLibrary> libraries = await repository.list();
    return LibrariesState(libraries: libraries);
  }

  Future<void> _migrateResourceFormatCategoriesFromLegacyIfNeeded() async {
    try {
      if ((await readFlag(_kMigratedResourceFormatCategoriesPref)) == true) {
        return;
      }
      final List<LocalLibrary> libraries = await repository.list();
      if (libraries.isEmpty) {
        await writeFlag(_kMigratedResourceFormatCategoriesPref, true);
        return;
      }
      final ({Object? enabledFormatGroups})? legacyPayload =
          await peekLegacyResourceFormatPayload();
      final List<ResourceFormatCategory> groups =
          resourceFormatCategoriesFromStorage(
            legacyPayload?.enabledFormatGroups,
          );
      for (final LocalLibrary library in libraries) {
        await repository.updateResourceFormatCategories(
          libraryId: library.libraryId,
          groups: groups,
        );
      }
      await writeFlag(_kMigratedResourceFormatCategoriesPref, true);
    } catch (_) {
      // Best-effort upgrade path; browse still works with DB defaults.
    }
  }

  Future<void> _migrateAutoScanFromLegacyIfNeeded() async {
    try {
      if ((await readFlag(_kMigratedAutoScanPref)) == true) {
        return;
      }
      final bool? legacy = await peekLegacyAutoScan();
      if (legacy == true) {
        await repository.setAllScanOnStartup(true);
      }
      await writeFlag(_kMigratedAutoScanPref, true);
    } catch (_) {
      // Best-effort; libraries keep scan_on_startup defaults.
    }
  }
}
