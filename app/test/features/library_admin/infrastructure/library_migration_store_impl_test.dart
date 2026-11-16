import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/library_admin/application/library_migration_store.dart';
import 'package:hentai_library/features/library_admin/infrastructure/library_migration_store_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const store = LibraryMigrationStoreImpl();

  test(
    'reads missing and existing legacy markers without changing them',
    () async {
      SharedPreferences.setMockInitialValues({
        'migrated_enabled_format_groups_to_libraries_v1': true,
        'migrated_auto_scan_to_libraries_v1': false,
      });
      expect(
        await store.isCompleted(LibraryPreferenceMigration.resourceFormats),
        isTrue,
      );
      expect(
        await store.isCompleted(LibraryPreferenceMigration.autoScan),
        isFalse,
      );
      SharedPreferences.setMockInitialValues({});
      expect(
        await store.isCompleted(LibraryPreferenceMigration.resourceFormats),
        isFalse,
      );
      expect(
        await store.isCompleted(LibraryPreferenceMigration.autoScan),
        isFalse,
      );
    },
  );

  test(
    'marks exactly one migration and retains unrelated preferences',
    () async {
      SharedPreferences.setMockInitialValues({'unrelated': 7});
      await store.markCompleted(LibraryPreferenceMigration.resourceFormats);
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getBool('migrated_enabled_format_groups_to_libraries_v1'),
        isTrue,
      );
      expect(prefs.containsKey('migrated_auto_scan_to_libraries_v1'), isFalse);
      await store.markCompleted(LibraryPreferenceMigration.autoScan);
      expect(prefs.getBool('migrated_auto_scan_to_libraries_v1'), isTrue);
      expect(prefs.getInt('unrelated'), 7);
      expect(prefs.getKeys(), {
        'unrelated',
        'migrated_enabled_format_groups_to_libraries_v1',
        'migrated_auto_scan_to_libraries_v1',
      });
    },
  );
}
