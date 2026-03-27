import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/v2/resource_parser.dart';
import 'package:hentai_library/data/services/comic/v2/resource_types.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ResourceParser.parse', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('resource_parser_test_');
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

    test('parses dir candidate when it is a pure image manga directory', () async {
      final mangaDir = Directory(p.join(tempDir.path, 'mangaA'));
      await mangaDir.create(recursive: true);
      await File(p.join(mangaDir.path, '1.jpg')).writeAsBytes([1, 2, 3]);

      final parser = ResourceParser();
      final parsed = await parser.parse((path: mangaDir.path, type: ResourceType.dir));

      expect(parsed, isNotNull);
      expect(parsed!.type, ResourceType.dir);
      expect(parsed.path, mangaDir.path);
      expect(parsed.meta.title, 'mangaA');
      expect(parsed.meta.authors, isEmpty);
    });

    test('parses zip candidate and returns title from filename', () async {
      final zipPath = await createMinimalZip(fileName: 'x.zip', entryName: '1.jpg');

      final parser = ResourceParser();
      final parsed = await parser.parse((path: zipPath, type: ResourceType.zip));

      expect(parsed, isNotNull);
      expect(parsed!.type, ResourceType.zip);
      expect(parsed.meta.title, 'x');
      expect(parsed.meta.authors, isEmpty);
    });

    test('parses cbz candidate and returns title from filename', () async {
      final cbzPath = await createMinimalZip(fileName: 'y.cbz', entryName: '1.jpg');

      final parser = ResourceParser();
      final parsed = await parser.parse((path: cbzPath, type: ResourceType.cbz));

      expect(parsed, isNotNull);
      expect(parsed!.type, ResourceType.cbz);
      expect(parsed.meta.title, 'y');
      expect(parsed.meta.authors, isEmpty);
    });

    test('returns null for cbr/rar placeholders', () async {
      final cbr = File(p.join(tempDir.path, 'a.cbr'))..writeAsBytesSync([0]);
      final rar = File(p.join(tempDir.path, 'b.rar'))..writeAsBytesSync([0]);

      final parser = ResourceParser();
      expect(await parser.parse((path: cbr.path, type: ResourceType.cbr)), isNull);
      expect(await parser.parse((path: rar.path, type: ResourceType.rar)), isNull);
    });

    test('returns null for invalid epub file', () async {
      final epub = File(p.join(tempDir.path, 'bad.epub'))..writeAsBytesSync([0, 1, 2]);

      final parser = ResourceParser();
      final parsed = await parser.parse((path: epub.path, type: ResourceType.epub));
      expect(parsed, isNull);
    });
  });
}

