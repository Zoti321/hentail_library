import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:hentai_library/services/comic/read_resource_get/comic_read_resource_exception.dart';
import 'package:hentai_library/services/comic/read_resource_get/comic_read_resource_opener.dart';
import 'package:hentai_library/services/comic/read_resource_get/reader_image.dart';
import 'package:hentai_library/model/enums.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('ComicReadResourceOpener', () {
    test('目录资源返回 ReaderFileImage 且页序正确', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'comic_read_dir_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      await File(p.join(temp.path, '002.png')).writeAsBytes(<int>[1, 2, 3]);
      await File(p.join(temp.path, '001.jpg')).writeAsBytes(<int>[4, 5, 6]);
      final ComicReadResourceOpener opener = ComicReadResourceOpener();
      final accessor = await opener.open(
        path: temp.path,
        type: ResourceType.dir,
      );
      expect(accessor.pageCount, 2);
      final ReaderImage page0 = await accessor.getPageImage(0);
      final ReaderImage page1 = await accessor.getPageImage(1);
      expect(page0, isA<ReaderFileImage>());
      expect(page1, isA<ReaderFileImage>());
      expect(p.basename((page0 as ReaderFileImage).file.path), '001.jpg');
      expect(p.basename((page1 as ReaderFileImage).file.path), '002.png');
      final ReaderImage cover = await accessor.getCoverImage();
      expect(cover, isA<ReaderFileImage>());
      expect(p.basename((cover as ReaderFileImage).file.path), '001.jpg');
      await accessor.dispose();
    });

    test('ZIP 资源返回 ReaderBytesImage', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'comic_read_zip_',
      );
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final Archive archive = Archive();
      archive.addFile(
        ArchiveFile('b.png', 3, Uint8List.fromList(<int>[10, 11, 12])),
      );
      archive.addFile(
        ArchiveFile('a.png', 3, Uint8List.fromList(<int>[7, 8, 9])),
      );
      final List<int> zipBytes = ZipEncoder().encode(archive)!;
      final File zipFile = File(p.join(temp.path, 'test.zip'));
      await zipFile.writeAsBytes(zipBytes);
      final ComicReadResourceOpener opener = ComicReadResourceOpener();
      final accessor = await opener.open(
        path: zipFile.path,
        type: ResourceType.zip,
      );
      expect(accessor.pageCount, 2);
      final ReaderImage p0 = await accessor.getPageImage(0);
      expect(p0, isA<ReaderBytesImage>());
      expect(
        (p0 as ReaderBytesImage).bytes,
        Uint8List.fromList(<int>[7, 8, 9]),
      );
      final ReaderImage cover = await accessor.getCoverImage();
      expect(cover, isA<ReaderBytesImage>());
      await accessor.dispose();
    });

    test('cbr 类型抛出不支持', () async {
      final Directory temp = await Directory.systemTemp.createTemp(
        'comic_read_cbr_',
      );
      final File file = File(p.join(temp.path, 'sample.cbr'));
      await file.writeAsBytes(<int>[1]);
      addTearDown(() async {
        if (await temp.exists()) {
          await temp.delete(recursive: true);
        }
      });
      final ComicReadResourceOpener opener = ComicReadResourceOpener();
      await expectLater(
        () => opener.open(path: file.path, type: ResourceType.cbr),
        throwsA(isA<ComicReadResourceUnsupportedTypeException>()),
      );
    });
  });
}
