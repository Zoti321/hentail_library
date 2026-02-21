import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/models/scanned_comic_model.dart';
import 'package:hentai_library/data/resources/local/database/dao.dart';
import 'package:hentai_library/data/services/comic/comic_file_cache.dart';
import 'package:hentai_library/data/services/comic/comic_sync_service.dart';
import 'package:hentai_library/data/services/comic/parser/directory_parse.dart';
import 'package:hentai_library/data/services/comic/scanner/comic_scanner.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

class MockComicDao extends Mock implements ComicDao {}

class MockDirectoryParseService extends Mock implements DirectoryParseService {}

class MockComicScannerService extends Mock implements ComicScannerService {}

class MockComicFileCacheService extends Mock implements ComicFileCacheService {}

void main() {
  late MockComicDao mockDao;
  late MockDirectoryParseService mockFolderParse;
  late MockComicScannerService mockScanner;
  late MockComicFileCacheService mockCache;
  late ComicSyncService syncService;
  late Directory tempDir;

  setUp(() {
    mockDao = MockComicDao();
    mockFolderParse = MockDirectoryParseService();
    mockScanner = MockComicScannerService();
    mockCache = MockComicFileCacheService();
    syncService = ComicSyncService(
      mockDao,
      mockFolderParse,
      mockScanner,
      mockCache,
    );
  });

  setUpAll(() async {
    registerFallbackValue(Directory('.'));
    tempDir = await Directory.systemTemp.createTemp('comic_sync_test_');
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  Future<String> createMinimalCbzInTemp() async {
    final imageBytes = <int>[1, 2, 3];
    final archive = Archive()
      ..addFile(ArchiveFile('1.jpg', imageBytes.length, imageBytes));
    final zipBytes = ZipEncoder().encode(archive);
    expect(zipBytes, isNotNull);
    final cbzFile = File(p.join(tempDir.path, 'comic.cbz'));
    await cbzFile.writeAsBytes(zipBytes!);
    return cbzFile.path;
  }

  group('runSync archive collection and report type', () {
    test('collects .cbz path and report item has type archive', () async {
      when(() => mockFolderParse.analyzeDirectory(any()))
          .thenAnswer((_) => Stream.empty());
      when(() => mockScanner.scanPath(any())).thenAnswer((invocation) async {
        final path = invocation.positionalArguments[0] as String;
        return ScannedComicModel(
          comicId: 'test-comic-id',
          title: 'Test',
          chapterId: 'test-chapter-id',
          imageDir: '/cache/content/test',
          sourcePath: path,
        );
      });
      when(() => mockDao.getAllComics()).thenAnswer((_) async => []);
      when(() => mockDao.getAllChapters()).thenAnswer((_) async => []);
      when(() => mockDao.batchInsertComics(any())).thenAnswer((_) async => {});
      when(() => mockDao.batchInsertChapters(any()))
          .thenAnswer((_) async => {});
      when(() => mockDao.batchDeleteComics(any())).thenAnswer((_) async => 0);
      when(() => mockDao.batchDeleteChapters(any())).thenAnswer((_) async => 0);
      when(() => mockCache.clearComicCache(any())).thenAnswer((_) async => {});

      await createMinimalCbzInTemp();

      final report = await syncService.runSync([tempDir.path]);

      expect(report, isNotNull);
      expect(report!.scannedItems.length, 1);
      expect(
        report.scannedItems.first.path.endsWith('.cbz'),
        isTrue,
      );
      expect(
        report.scannedItems.first.type,
        ScannedItemType.archive,
      );
    });
  });
}
