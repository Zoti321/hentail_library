import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_auto_backup_schedule.dart';
import 'package:hentai_library/features/metadata_backup/domain/metadata_export_options.dart';

void main() {
  test('shouldRunStartupMetadataAutoBackup', () {
    final DateTime now = DateTime.utc(2026, 1, 8);
    expect(
      shouldRunStartupMetadataAutoBackup(now: now, lastBackupAt: null),
      isTrue,
    );
    expect(
      shouldRunStartupMetadataAutoBackup(
        now: now,
        lastBackupAt: now.subtract(const Duration(days: 8)),
      ),
      isTrue,
    );
    expect(
      shouldRunStartupMetadataAutoBackup(
        now: now,
        lastBackupAt: now.subtract(const Duration(days: 1)),
      ),
      isFalse,
    );
  });

  test('MetadataExportOptions.isValid', () {
    expect(
      const MetadataExportOptions(currentLibraryOnly: true).isValid,
      isFalse,
    );
    expect(
      const MetadataExportOptions(
        currentLibraryOnly: true,
        libraryId: ' lib ',
      ).normalized().isValid,
      isTrue,
    );
  });
}
