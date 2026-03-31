import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/comic_scan_parse_service.dart';
import 'package:hentai_library/data/services/comic/resource_parser.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/util/enums.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ComicScanParseService.scanAndParseRoots', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('comic_scan_parse_test_');
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    Future<String> createMinimalZip({
      required String fileName,
      required String entryName,
    }) async {
      final imageBytes = <int>[1, 2, 3];
      final archive = Archive()
        ..addFile(ArchiveFile(entryName, imageBytes.length, imageBytes));
      final zipBytes = ZipEncoder().encode(archive);
      expect(zipBytes, isNotNull);
      final file = File(p.join(tempDir.path, fileName));
      await file.writeAsBytes(zipBytes!);
      return file.path;
    }

    ComicScanParseService makeService() => ComicScanParseService(
      parsers: defaultComicResourceParsers(),
      parseContext: defaultComicParseContext(),
    );

    test(
      'collects manga image directory as dir and does not recurse into it',
      () async {
        final mangaDir = Directory(p.join(tempDir.path, 'manga1'));
        await mangaDir.create(recursive: true);
        await File(p.join(mangaDir.path, '1.jpg')).writeAsBytes([1, 2, 3]);

        final service = makeService();
        final result = await service.scanAndParseRoots([tempDir.path]).toList();

        expect(
          result.any(
            (e) => e.path == mangaDir.path && e.type == ResourceType.dir,
          ),
          isTrue,
        );
      },
    );

    test(
      'recurses non-manga directory and yields nested manga dir and zip/cbz',
      () async {
        final root = Directory(p.join(tempDir.path, 'root'));
        await root.create(recursive: true);

        final sub = Directory(p.join(root.path, 'sub'));
        await sub.create(recursive: true);
        await File(p.join(sub.path, 'cover.png')).writeAsBytes([1, 2, 3]);

        final epubFile = File(p.join(root.path, 'a.epub'));
        await epubFile.writeAsBytes([0, 1, 2]);

        final zipPath = await createMinimalZip(
          fileName: p.join('root', 'b.zip'),
          entryName: '1.jpg',
        );
        final cbzPath = await createMinimalZip(
          fileName: p.join('root', 'c.cbz'),
          entryName: '1.jpg',
        );

        final cbrFile = File(p.join(root.path, 'd.cbr'))..writeAsBytesSync([0]);
        final rarFile = File(p.join(root.path, 'e.rar'))..writeAsBytesSync([0]);

        final service = makeService();
        final result = await service.scanAndParseRoots([root.path]).toList();

        expect(
          result.any((e) => e.path == sub.path && e.type == ResourceType.dir),
          isTrue,
        );
        expect(
          result.any((e) => e.path == zipPath && e.type == ResourceType.zip),
          isTrue,
        );
        expect(
          result.any((e) => e.path == cbzPath && e.type == ResourceType.cbz),
          isTrue,
        );
        expect(result.any((e) => e.path == epubFile.path), isFalse);
        expect(result.any((e) => e.path == cbrFile.path), isFalse);
        expect(result.any((e) => e.path == rarFile.path), isFalse);
      },
    );
  });
}
