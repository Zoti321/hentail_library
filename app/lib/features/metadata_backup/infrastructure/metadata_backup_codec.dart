import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

Future<Uint8List> decodeMetadataBackupFileBytes(
  List<int> rawBytes,
  String path,
) async {
  final String lower = path.toLowerCase();
  if (lower.endsWith('.gz') || lower.endsWith('.hlmeta.json.gz')) {
    return Isolate.run(() => Uint8List.fromList(GZipCodec().decode(rawBytes)));
  }
  return Uint8List.fromList(rawBytes);
}

Future<Uint8List> encodeMetadataBackupGzip(Uint8List raw) {
  return Isolate.run(() => Uint8List.fromList(GZipCodec().encode(raw)));
}
