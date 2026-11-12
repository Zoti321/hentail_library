/// Filename conventions for metadata backup files (domain-owned; no I/O).
const String metadataBackupFilePrefix = 'metadata-';
const String metadataBackupExtension = '.hlmeta.json.gz';
String metadataAutoBackupFileName(DateTime timestamp) {
  final String stamp =
      '${timestamp.year.toString().padLeft(4, '0')}'
      '${timestamp.month.toString().padLeft(2, '0')}'
      '${timestamp.day.toString().padLeft(2, '0')}-'
      '${timestamp.hour.toString().padLeft(2, '0')}'
      '${timestamp.minute.toString().padLeft(2, '0')}'
      '${timestamp.second.toString().padLeft(2, '0')}';
  return '$metadataBackupFilePrefix$stamp$metadataBackupExtension';
}
