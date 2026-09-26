import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/metadata/metadata_auto_backup_logic.dart';
import 'package:hentai_library/core/metadata/metadata_backup_paths.dart';

void main() {
  group('shouldRunStartupMetadataAutoBackup', () {
    test('returns true when never backed up', () {
      expect(
        shouldRunStartupMetadataAutoBackup(
          now: DateTime(2026, 1, 8),
          lastBackupAt: null,
        ),
        isTrue,
      );
    });

    test('returns false when last backup is within 7 days', () {
      expect(
        shouldRunStartupMetadataAutoBackup(
          now: DateTime(2026, 1, 8),
          lastBackupAt: DateTime(2026, 1, 2),
        ),
        isFalse,
      );
    });

    test('returns true when last backup is at least 7 days ago', () {
      expect(
        shouldRunStartupMetadataAutoBackup(
          now: DateTime(2026, 1, 8),
          lastBackupAt: DateTime(2026, 1, 1),
        ),
        isTrue,
      );
    });
  });

  group('pruneMetadataBackupFiles', () {
    test('keeps newest three metadata backup files', () async {
      final Directory tempDir = Directory.systemTemp.createTempSync(
        'metadata_backup_prune_',
      );
      addTearDown(() {
        try {
          tempDir.deleteSync(recursive: true);
        } on FileSystemException {
          // Windows may keep handles briefly.
        }
      });

      for (int index = 0; index < 4; index++) {
        final File file = File(
          '${tempDir.path}/$metadataBackupFilePrefix$index$metadataBackupExtension',
        );
        file.writeAsStringSync('backup-$index');
        file.setLastModifiedSync(DateTime(2026, 1, 1, 12, 0, index));
      }

      pruneMetadataBackupFiles(tempDir.path, maxFiles: 3);

      final List<File> remaining = listMetadataBackupFiles(tempDir.path);
      expect(remaining, hasLength(3));
      expect(remaining.first.readAsStringSync(), 'backup-3');
      expect(
        remaining.map((File file) => file.readAsStringSync()).toList(),
        isNot(contains('backup-0')),
      );
    });
  });
}
