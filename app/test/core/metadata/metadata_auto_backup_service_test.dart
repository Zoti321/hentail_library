import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/metadata/metadata_auto_backup_service.dart';
import 'package:hentai_library/core/metadata/metadata_backup_paths.dart';

void main() {
  test('runMetadataAutoBackup writes gzip file and prunes old copies', () async {
    final Directory tempDir = Directory.systemTemp.createTempSync(
      'metadata_auto_backup_service_',
    );
    addTearDown(() {
      try {
        tempDir.deleteSync(recursive: true);
      } on FileSystemException {
        // Windows may keep handles briefly.
      }
    });

    for (int index = 0; index < 3; index++) {
      await runMetadataAutoBackup(
        export: (_) => Uint8List.fromList(<int>[index]),
        now: () => DateTime(2026, 1, 10, 12, 0, index),
        directoryPathOverride: tempDir.path,
      );
    }

    final MetadataAutoBackupRunResult result = await runMetadataAutoBackup(
      export: (_) => Uint8List.fromList(<int>[9, 9, 9]),
      now: () => DateTime(2026, 1, 10, 12, 0, 3),
      directoryPathOverride: tempDir.path,
    );

    expect(result.outputPath, contains(metadataBackupExtension));
    final List<FileSystemEntity> afterFourth = tempDir
        .listSync()
        .whereType<File>()
        .toList();
    expect(afterFourth, hasLength(3));
    expect(
      File(result.outputPath).readAsBytesSync(),
      equals(GZipCodec().encode(<int>[9, 9, 9])),
    );
  });
}
