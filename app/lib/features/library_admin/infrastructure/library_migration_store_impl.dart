import 'package:hentai_library/features/library_admin/application/library_migration_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LibraryMigrationStoreImpl implements LibraryMigrationStore {
  const LibraryMigrationStoreImpl();

  @override
  Future<bool> isCompleted(LibraryPreferenceMigration migration) async =>
      (await SharedPreferences.getInstance()).getBool(_key(migration)) ?? false;

  @override
  Future<void> markCompleted(LibraryPreferenceMigration migration) async {
    await (await SharedPreferences.getInstance()).setBool(
      _key(migration),
      true,
    );
  }

  String _key(LibraryPreferenceMigration migration) => switch (migration) {
    LibraryPreferenceMigration.resourceFormats =>
      'migrated_enabled_format_groups_to_libraries_v1',
    LibraryPreferenceMigration.autoScan => 'migrated_auto_scan_to_libraries_v1',
  };
}
