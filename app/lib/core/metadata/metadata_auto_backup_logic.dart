import 'dart:io';

import 'package:hentai_library/core/metadata/metadata_backup_paths.dart';
import 'package:path/path.dart' as p;

const Duration metadataAutoBackupStartupInterval = Duration(days: 7);
const Duration metadataAutoBackupSaveDebounce = Duration(minutes: 5);
const int metadataAutoBackupMaxFiles = 3;

bool shouldRunStartupMetadataAutoBackup({
  required DateTime now,
  DateTime? lastBackupAt,
}) {
  if (lastBackupAt == null) {
    return true;
  }
  return now.difference(lastBackupAt) >= metadataAutoBackupStartupInterval;
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
        (File file) => p
            .basename(file.path)
            .startsWith(metadataBackupFilePrefix),
      )
      .toList();
  files.sort((File a, File b) {
    final int modified = b.lastModifiedSync().compareTo(
      a.lastModifiedSync(),
    );
    if (modified != 0) {
      return modified;
    }
    // Filename embeds timestamp; use as tiebreaker when mtimes match.
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
