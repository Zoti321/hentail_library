import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/metadata_backup/infrastructure/metadata_backup_preferences_repository_impl.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const repository = MetadataBackupPreferencesRepositoryImpl();

  test(
    'missing preferences preserve enabled-by-default and absent completion',
    () async {
      SharedPreferences.setMockInitialValues({});
      expect(await repository.loadEnabled(), isTrue);
      expect(await repository.loadLastBackupAt(), isNull);
    },
  );

  test(
    'reads existing keys and updates only the corresponding preference',
    () async {
      SharedPreferences.setMockInitialValues({
        'metadata_auto_backup_enabled_v1': false,
        'metadata_last_auto_backup_at_v1': 1234,
        'unrelated': 'keep',
      });
      expect(await repository.loadEnabled(), isFalse);
      expect(
        (await repository.loadLastBackupAt())?.millisecondsSinceEpoch,
        1234,
      );
      await repository.saveEnabled(true);
      expect(
        (await repository.loadLastBackupAt())?.millisecondsSinceEpoch,
        1234,
      );
      final at = DateTime(2026, 11, 13, 11);
      await repository.recordBackup(at);
      expect(await repository.loadLastBackupAt(), at);
      expect(await repository.loadEnabled(), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('metadata_auto_backup_enabled_v1'), isTrue);
      expect(
        prefs.getInt('metadata_last_auto_backup_at_v1'),
        at.millisecondsSinceEpoch,
      );
      expect(prefs.getString('unrelated'), 'keep');
    },
  );
}
