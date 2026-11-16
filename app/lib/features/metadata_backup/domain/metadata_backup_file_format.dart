bool isMetadataBackupFilePath(String path) {
  final String lower = path.toLowerCase();
  return lower.endsWith('.hlmeta.json') || lower.endsWith('.hlmeta.json.gz');
}
