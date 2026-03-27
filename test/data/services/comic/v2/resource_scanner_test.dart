import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/resource_scanner.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:path/path.dart' as p;

void main() {
  group('ResourceScanner.scanRoots', () {
    late Directory tempDir;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp('resource_scanner_test_');
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

    test(
      'collects manga image directory as dir and does not recurse into it',
      () async {
        final mangaDir = Directory(p.join(tempDir.path, 'manga1'));
        await mangaDir.create(recursive: true);
        await File(p.join(mangaDir.path, '1.jpg')).writeAsBytes([1, 2, 3]);

        final scanner = ResourceScanner();
        final result = await scanner.scanRoots([tempDir.path]).toList();

        expect(
          result.any(
            (e) => e.path == mangaDir.path && e.type == ResourceType.dir,
          ),
          isTrue,
        );
      },
    );

    test(
      'recurses non-manga directory and collects nested manga dir and files',
      () async {
        final root = Directory(p.join(tempDir.path, 'root'));
        await root.create(recursive: true);

        final sub = Directory(p.join(root.path, 'sub'));
        await sub.create(recursive: true);
        await File(p.join(sub.path, 'cover.png')).writeAsBytes([1, 2, 3]);

        final epubFile = File(p.join(root.path, 'a.epub'));
        await epubFile.writeAsBytes([0, 1, 2]); // 不要求是有效 epub，仅测试收集类型

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

        final scanner = ResourceScanner();
        final result = await scanner.scanRoots([root.path]).toList();

        expect(
          result.any((e) => e.path == sub.path && e.type == ResourceType.dir),
          isTrue,
        );
        expect(
          result.any(
            (e) => e.path == epubFile.path && e.type == ResourceType.epub,
          ),
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
        expect(
          result.any(
            (e) => e.path == cbrFile.path && e.type == ResourceType.cbr,
          ),
          isTrue,
        );
        expect(
          result.any(
            (e) => e.path == rarFile.path && e.type == ResourceType.rar,
          ),
          isTrue,
        );
      },
    );
  });
}
