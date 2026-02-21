import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/comic_file_cache.dart';
import 'package:hentai_library/data/services/comic/scanner/comic_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

class MockComicFileCacheService extends Mock implements ComicFileCacheService {}

void main() {
  late MockComicFileCacheService mockCache;
  late ComicScannerService scanner;
  late Directory tempDir;
  const contentDirPath = '/cache/content/id1';
  const coverDirPath = '/cache/covers/id1';

  setUpAll(() async {
    registerFallbackValue(Uint8List(0));
    registerFallbackValue(<(Uint8List, String)>[]);
  });

  setUp(() async {
    mockCache = MockComicFileCacheService();
    scanner = ComicScannerService(cacheService: mockCache);
    tempDir = await Directory.systemTemp.createTemp('comic_scanner_test_');
  });

  tearDown(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  Future<String> createMinimalZipWithOneImage() async {
    final imageBytes = <int>[1, 2, 3];
    final archive = Archive()
      ..addFile(ArchiveFile('1.jpg', imageBytes.length, imageBytes));
    final zipBytes = ZipEncoder().encode(archive);
    expect(zipBytes, isNotNull);
    final zipFile = File(p.join(tempDir.path, 'comic.cbz'));
    await zipFile.writeAsBytes(zipBytes!);
    return zipFile.path;
  }

  group('scanPath (ZIP)', () {
    test('returns ScannedComicModel and calls saveCover and saveContentImages', () async {
      when(() => mockCache.getContentCacheDir(any()))
          .thenAnswer((_) async => contentDirPath);
      when(() => mockCache.getCoverCacheDir(any()))
          .thenAnswer((_) async => coverDirPath);
      when(() => mockCache.saveCover(any(), any(), extension: any(named: 'extension')))
          .thenAnswer((_) async => '');
      when(() => mockCache.saveContentImages(any(), any()))
          .thenAnswer((_) async => {});

      final zipPath = await createMinimalZipWithOneImage();

      final result = await scanner.scanPath(zipPath);

      expect(result, isNotNull);
      expect(result!.sourcePath, zipPath);
      expect(result.pageCount, 1);
      expect(result.title, p.basenameWithoutExtension(zipPath));
      expect(result.imageDir, contentDirPath);

      verify(() => mockCache.saveCover(any(), any(), extension: any(named: 'extension')))
          .called(1);
      verify(() => mockCache.saveContentImages(any(), any())).called(1);
    });
  });
}
