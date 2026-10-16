import 'dart:io';
import 'dart:typed_data';

Uint8List decodeMetadataBackupFileBytes(List<int> rawBytes, String path) {
  final String lower = path.toLowerCase();
  if (lower.endsWith('.gz') || lower.endsWith('.hlmeta.json.gz')) {
    return Uint8List.fromList(GZipCodec().decode(rawBytes));
  }
  return Uint8List.fromList(rawBytes);
}

bool isMetadataBackupFilePath(String path) {
  final String lower = path.toLowerCase();
  return lower.endsWith('.hlmeta.json') || lower.endsWith('.hlmeta.json.gz');
}
