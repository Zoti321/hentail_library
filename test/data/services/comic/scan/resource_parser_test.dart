import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:hentai_library/data/services/comic/scan/resource_parser.dart';
import 'package:hentai_library/data/services/comic/scan/resource_types.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('DirResourceParser', () {
    test('识别仅包含 gif 图片的目录资源', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'scan_dir_gif_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      await File(p.join(tempDir.path, '001.gif')).writeAsBytes(<int>[1, 2, 3]);
      await File(p.join(tempDir.path, '002.gif')).writeAsBytes(<int>[4, 5, 6]);
      final DirResourceParser parser = DirResourceParser();
      final ParsedResource? actualParsed = await parser.parse(
        tempDir,
        defaultComicParseContext(),
      );
      expect(actualParsed, isNotNull);
      expect(actualParsed!.type, ResourceType.dir);
      expect(actualParsed.meta.pageCount, 2);
    });
  });
  group('PureImageZipParser', () {
    test('识别包含 gif 图片的 zip 资源', () async {
      final Directory tempDir = await Directory.systemTemp.createTemp(
        'scan_zip_gif_',
      );
      addTearDown(() async {
        if (await tempDir.exists()) {
          await tempDir.delete(recursive: true);
        }
      });
      final Archive archive = Archive();
      archive.addFile(
        ArchiveFile('images/001.gif', 3, Uint8List.fromList(<int>[7, 8, 9])),
      );
      archive.addFile(
        ArchiveFile('notes/readme.txt', 3, Uint8List.fromList(<int>[1, 2, 3])),
      );
      final List<int> zipBytes = ZipEncoder().encode(archive)!;
      final File zipFile = File(p.join(tempDir.path, 'sample.zip'));
      await zipFile.writeAsBytes(zipBytes);
      final PureImageZipParser parser = PureImageZipParser();
      final ParsedResource? actualParsed = await parser.parse(
        zipFile,
        defaultComicParseContext(),
      );
      expect(actualParsed, isNotNull);
      expect(actualParsed!.type, ResourceType.zip);
      expect(actualParsed.path, zipFile.path);
    });
  });
}
