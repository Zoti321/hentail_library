abstract interface class MetadataBackupPreferencesRepository {
  Future<bool> loadEnabled();
  Future<void> saveEnabled(bool enabled);
  Future<DateTime?> loadLastBackupAt();
  Future<void> recordBackup(DateTime completedAt);
}
