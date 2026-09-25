import 'dart:io';
import 'dart:typed_data';

import 'package:hentai_library/core/metadata/metadata_auto_backup_logic.dart';
import 'package:hentai_library/core/metadata/metadata_backup_paths.dart';
import 'package:hentai_library/src/rust/api/metadata_backup.dart';
import 'package:path/path.dart' as p;

typedef MetadataAutoBackupExportInvoker =
    Uint8List Function(ExportComicMetadataOptionsDto options);

class MetadataAutoBackupRunResult {
  const MetadataAutoBackupRunResult({
    required this.outputPath,
    required this.completedAt,
  });

  final String outputPath;
  final DateTime completedAt;
}

Future<MetadataAutoBackupRunResult> runMetadataAutoBackup({
  required MetadataAutoBackupExportInvoker export,
  DateTime Function()? now,
  String? directoryPathOverride,
}) async {
  final DateTime timestamp = now?.call() ?? DateTime.now();
  final String directoryPath =
      directoryPathOverride ?? await metadataBackupsDirectory();
  await Directory(directoryPath).create(recursive: true);

  final Uint8List raw = export(
    const ExportComicMetadataOptionsDto(includeOrphanFacets: false),
  );
  final List<int> compressed = GZipCodec().encode(raw);
  final String fileName = metadataAutoBackupFileName(timestamp);
  final String outputPath = p.join(directoryPath, fileName);
  await File(outputPath).writeAsBytes(compressed, flush: true);

  pruneMetadataBackupFiles(
    directoryPath,
    maxFiles: metadataAutoBackupMaxFiles,
  );

  return MetadataAutoBackupRunResult(
    outputPath: outputPath,
    completedAt: timestamp,
  );
}
