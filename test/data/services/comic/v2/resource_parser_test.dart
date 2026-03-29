import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/comic_scan_parse_service.dart';
import 'package:hentai_library/data/services/comic/resource_parser.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:path/path.dart' as p;

void main() {
  group('comic/parser ResourceParser', () {
    late Directory tempDir;
    late ParseContext ctx;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('resource_parser_test_');
      ctx = defaultComicParseContext();
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

    test('DirResourceParser parses pure image manga directory', () async {
      final mangaDir = Directory(p.join(tempDir.path, 'mangaA'));
      await mangaDir.create(recursive: true);
      await File(p.join(mangaDir.path, '1.jpg')).writeAsBytes([1, 2, 3]);

      final parser = DirResourceParser();
      final parsed = await parser.parse(mangaDir, ctx);

      expect(parsed, isNotNull);
      expect(parsed!.type, ResourceType.dir);
      expect(parsed.path, mangaDir.path);
      expect(parsed.meta.title, 'mangaA');
      expect(parsed.meta.authors, isEmpty);
    });

    test('PureImageZipParser returns title from filename', () async {
      final zipPath = await createMinimalZip(
        fileName: 'x.zip',
        entryName: '1.jpg',
      );

      final parser = PureImageZipParser();
      final parsed = await parser.parse(File(zipPath), ctx);

      expect(parsed, isNotNull);
      expect(parsed!.type, ResourceType.zip);
      expect(parsed.meta.title, 'x');
      expect(parsed.meta.authors, isEmpty);
    });

    test('PureImageCbzParser returns title from filename', () async {
      final cbzPath = await createMinimalZip(
        fileName: 'y.cbz',
        entryName: '1.jpg',
      );

      final parser = PureImageCbzParser();
      final parsed = await parser.parse(File(cbzPath), ctx);

      expect(parsed, isNotNull);
      expect(parsed!.type, ResourceType.cbz);
      expect(parsed.meta.title, 'y');
      expect(parsed.meta.authors, isEmpty);
    });

    test('cbr/rar files yield no parsed resource (no parser)', () async {
      final cbr = File(p.join(tempDir.path, 'a.cbr'))..writeAsBytesSync([0]);
      final rar = File(p.join(tempDir.path, 'b.rar'))..writeAsBytesSync([0]);

      final service = ComicScanParseService(
        parsers: defaultComicResourceParsers(),
        parseContext: ctx,
      );
      final out = await service.scanAndParseRoots([
        cbr.path,
        rar.path,
      ]).toList();
      expect(out, isEmpty);
    });

    test('ComicEpubParser returns null for invalid epub file', () async {
      final epub = File(p.join(tempDir.path, 'bad.epub'))
        ..writeAsBytesSync([0, 1, 2]);

      final parser = ComicEpubParser();
      final parsed = await parser.parse(epub, ctx);
      expect(parsed, isNull);
    });
  });
}
