import 'package:hentai_library/features/library_admin/application/library_migration_store.dart';
import 'package:hentai_library/features/library_admin/domain/libraries_state.dart';
import 'package:hentai_library/features/library_admin/domain/local_library.dart';
import 'package:hentai_library/features/library_admin/domain/library_repository.dart';
import 'package:hentai_library/features/library_admin/domain/resource_format_category.dart';

/// 在列表读取前执行旧配置迁移及暂存清理。
///
/// 迁移与清理保留 best-effort 行为，最终列表读取错误继续向上传播。
class LoadLibrariesUseCase {
  LoadLibrariesUseCase({
    required this.repository,
    required this.migrations,
    required this.peekLegacyResourceFormatPayload,
    required this.peekLegacyAutoScan,
    required this.clearLegacyImportPayload,
  });
  final LibraryRepository repository;
  final LibraryMigrationStore migrations;
  final Future<({Object? enabledFormatGroups})?> Function()
  peekLegacyResourceFormatPayload;
  final Future<bool?> Function() peekLegacyAutoScan;
  final Future<void> Function() clearLegacyImportPayload;
  Future<void>? _preparation;

  Future<LibrariesState> call() async {
    await _prepareIfNeeded();
    final List<LocalLibrary> libraries = await repository.list();
    return LibrariesState(libraries: libraries);
  }

  Future<void> _prepareIfNeeded() async {
    final current = _preparation;
    if (current != null) {
      await current;
      return;
    }
    // Reserve preparation before invoking injected migration callbacks.
    final pending = Future<void>.microtask(_prepare);
    _preparation = pending;
    try {
      await pending;
    } finally {
      if (identical(_preparation, pending)) {
        _preparation = null;
      }
    }
  }

  Future<void> _prepare() async {
    final formatsCompleted =
        await _migrateResourceFormatCategoriesFromLegacyIfNeeded();
    final autoScanCompleted = await _migrateAutoScanFromLegacyIfNeeded();
    if (!formatsCompleted || !autoScanCompleted) {
      return;
    }
    try {
      await clearLegacyImportPayload();
    } catch (_) {
      // Best-effort cleanup of staged legacy import keys.
    }
  }

  Future<bool> _migrateResourceFormatCategoriesFromLegacyIfNeeded() async {
    try {
      if (await migrations.isCompleted(
        LibraryPreferenceMigration.resourceFormats,
      )) {
        return true;
      }
      final List<LocalLibrary> libraries = await repository.list();
      if (libraries.isEmpty) {
        await migrations.markCompleted(
          LibraryPreferenceMigration.resourceFormats,
        );
        return true;
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
      await migrations.markCompleted(
        LibraryPreferenceMigration.resourceFormats,
      );
      return true;
    } catch (_) {
      // Best-effort upgrade path; browse still works with DB defaults.
      return false;
    }
  }

  Future<bool> _migrateAutoScanFromLegacyIfNeeded() async {
    try {
      if (await migrations.isCompleted(LibraryPreferenceMigration.autoScan)) {
        return true;
      }
      final bool? legacy = await peekLegacyAutoScan();
      if (legacy == true) {
        await repository.setAllScanOnStartup(true);
      }
      await migrations.markCompleted(LibraryPreferenceMigration.autoScan);
      return true;
    } catch (_) {
      // Best-effort; libraries keep scan_on_startup defaults.
      return false;
    }
  }
}
