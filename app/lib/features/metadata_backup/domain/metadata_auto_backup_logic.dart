import 'dart:io';

import 'package:hentai_library/features/metadata_backup/domain/metadata_auto_backup_schedule_specification.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_backup_naming.dart';
import 'package:path/path.dart' as p;

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

List<File> listMetadataBackupFiles(String directoryPath) {
  final Directory directory = Directory(directoryPath);
  if (!directory.existsSync()) {
    return <File>[];
  }
  final List<File> files = directory
      .listSync()
      .whereType<File>()
      .where(
        (File file) =>
            p.basename(file.path).startsWith(metadataBackupFilePrefix),
      )
      .toList();
  files.sort((File a, File b) {
    final int modified = b.lastModifiedSync().compareTo(a.lastModifiedSync());
    if (modified != 0) {
      return modified;
    }
    return b.path.compareTo(a.path);
  });
  return files;
}

void pruneMetadataBackupFiles(String directoryPath, {int maxFiles = 3}) {
  final List<File> files = listMetadataBackupFiles(directoryPath);
  if (files.length <= maxFiles) {
    return;
  }
  for (final File file in files.skip(maxFiles)) {
    try {
      file.deleteSync();
    } on FileSystemException {
      // Best-effort rotation.
    }
  }
}
