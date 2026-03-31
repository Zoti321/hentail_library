import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/comic_resource_getting_service.dart';

import 'package:hentai_library/domain/util/enums.dart' show ResourceType;
import 'package:path/path.dart' as p;

void main() {
  group('ComicResourceGettingService', () {
    late Directory tempDir;
    late ComicResourceGettingService service;

    setUp(() async {
      tempDir = await Directory.systemTemp.createTemp(
        'comic_resource_getting_test_',
      );
      service = ComicResourceGettingService();
    });

    tearDown(() async {
      try {
        await tempDir.delete(recursive: true);
      } catch (_) {}
    });

    test('getComicContent returns sorted image files for dir', () async {
      final mangaDir = Directory(p.join(tempDir.path, 'manga'));
      await mangaDir.create(recursive: true);
      await File(p.join(mangaDir.path, 'b.png')).writeAsBytes([1]);
      await File(p.join(mangaDir.path, 'a.jpg')).writeAsBytes([2]);
      await File(p.join(mangaDir.path, 'note.txt')).writeAsString('x');

      final files = await service.getComicContent(
        mangaDir.path,
        ResourceType.dir,
      );

      expect(files.length, 2);
      expect(p.basename(files[0].path), 'a.jpg');
      expect(p.basename(files[1].path), 'b.png');
    });

    test('getComicCover prefers file named cover', () async {
      final mangaDir = Directory(p.join(tempDir.path, 'manga'));
      await mangaDir.create(recursive: true);
      await File(p.join(mangaDir.path, '001.jpg')).writeAsBytes([1]);
      await File(p.join(mangaDir.path, 'cover.png')).writeAsBytes([2]);

      final cover = await service.getComicCover(
        mangaDir.path,
        ResourceType.dir,
      );

      expect(p.basename(cover.path), 'cover.png');
    });

    test('getComicCover uses first sorted image when no cover', () async {
      final mangaDir = Directory(p.join(tempDir.path, 'manga'));
      await mangaDir.create(recursive: true);
      await File(p.join(mangaDir.path, 'z.jpg')).writeAsBytes([1]);
      await File(p.join(mangaDir.path, 'a.webp')).writeAsBytes([2]);

      final cover = await service.getComicCover(
        mangaDir.path,
        ResourceType.dir,
      );

      expect(p.basename(cover.path), 'a.webp');
    });

    test(
      'throws when type does not match path (file path with dir type)',
      () async {
        final f = File(p.join(tempDir.path, 'x.zip'));
        await f.writeAsBytes([1, 2, 3]);

        expect(
          () => service.getComicContent(f.path, ResourceType.dir),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.message,
              'message',
              contains('不一致'),
            ),
          ),
        );
      },
    );

    test('throws when path is empty', () async {
      expect(
        () => service.getComicCover('  ', ResourceType.dir),
        throwsA(
          isA<ArgumentError>().having(
            (e) => e.message,
            'message',
            contains('不能为空'),
          ),
        ),
      );
    });

    test('getComicCover throws when dir has no images', () async {
      final emptyDir = Directory(p.join(tempDir.path, 'empty'));
      await emptyDir.create(recursive: true);

      expect(
        () => service.getComicCover(emptyDir.path, ResourceType.dir),
        throwsA(isA<StateError>()),
      );
    });

    test('throws UnsupportedError for zip type', () async {
      final f = File(p.join(tempDir.path, 'x.zip'));
      await f.writeAsBytes([1, 2, 3]);

      expect(
        () => service.getComicCover(f.path, ResourceType.zip),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });
}
