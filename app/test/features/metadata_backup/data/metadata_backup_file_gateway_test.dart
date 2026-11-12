import 'dart:io';
import 'dart:typed_data';

import 'package:test/test.dart';
import 'package:hentai_library/features/metadata_backup/data/metadata_backup_file_gateway.dart';

void main() {
  test('file gateway writes compressed bytes to an isolated path', () async {
    final directory = await Directory.systemTemp.createTemp(
      'metadata_gateway_',
    );
    final path = '${directory.path}/backup.hlmeta.json.gz';
    final gateway = const LocalMetadataBackupFileGateway();
    try {
      final compressed = await gateway.compress(Uint8List.fromList([1, 2, 3]));
      await gateway.write(path, compressed);
      expect(await gateway.decode(await File(path).readAsBytes(), path), [
        1,
        2,
        3,
      ]);
      expect(GZipCodec().decode(await File(path).readAsBytes()), [1, 2, 3]);
    } finally {
      if (await File(path).exists()) await File(path).delete();
      await directory.delete();
    }
  });
}
