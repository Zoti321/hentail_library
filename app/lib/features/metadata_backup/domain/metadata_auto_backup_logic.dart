import 'package:hentai_library/features/metadata_backup/domain/metadata_auto_backup_schedule_specification.dart';

export 'metadata_auto_backup_schedule_specification.dart';

const Duration metadataAutoBackupStartupInterval =
    MetadataAutoBackupScheduleSpecification.startupInterval;
const Duration metadataAutoBackupSaveDebounce =
    MetadataAutoBackupScheduleSpecification.saveDebounce;
const int metadataAutoBackupMaxFiles =
    MetadataAutoBackupScheduleSpecification.maxFiles;

bool shouldRunStartupMetadataAutoBackup({
  required DateTime now,
  DateTime? lastBackupAt,
}) {
  return MetadataAutoBackupScheduleSpecification.shouldRunStartupBackup(
    now: now,
    lastBackupAt: lastBackupAt,
  );
}
