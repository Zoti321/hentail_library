import 'dart:io';
import 'dart:typed_data';

Future<Uint8List?> readTagDictionaryFile({
  Uint8List? bytes,
  String? path,
}) async {
  if (bytes != null && bytes.isNotEmpty) {
    return Uint8List.fromList(bytes);
  }
  if (path == null || path.isEmpty) {
    return null;
  }
  try {
    return await File(path).readAsBytes();
  } catch (_) {
    return null;
  }
}
