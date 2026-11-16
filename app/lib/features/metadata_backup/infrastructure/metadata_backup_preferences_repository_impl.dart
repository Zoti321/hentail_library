import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_preferences_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String metadataAutoBackupStorageKey = 'metadata_auto_backup_enabled_v1';
const String metadataLastAutoBackupAtStorageKey =
    'metadata_last_auto_backup_at_v1';

class MetadataBackupPreferencesRepositoryImpl
    implements MetadataBackupPreferencesRepository {
  const MetadataBackupPreferencesRepositoryImpl();

  @override
  Future<bool> loadEnabled() async =>
      (await SharedPreferences.getInstance()).getBool(
        metadataAutoBackupStorageKey,
      ) ??
      true;

  @override
  Future<void> saveEnabled(bool enabled) async {
    await (await SharedPreferences.getInstance()).setBool(
      metadataAutoBackupStorageKey,
      enabled,
    );
  }

  @override
  Future<DateTime?> loadLastBackupAt() async {
    final millis = (await SharedPreferences.getInstance()).getInt(
      metadataLastAutoBackupAtStorageKey,
    );
    return millis == null ? null : DateTime.fromMillisecondsSinceEpoch(millis);
  }

  @override
  Future<void> recordBackup(DateTime completedAt) async {
    await (await SharedPreferences.getInstance()).setInt(
      metadataLastAutoBackupAtStorageKey,
      completedAt.millisecondsSinceEpoch,
    );
  }
}
