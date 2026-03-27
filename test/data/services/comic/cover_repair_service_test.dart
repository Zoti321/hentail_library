import 'dart:io';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/cover_repair_service.dart';
import 'package:hentai_library/data/services/comic/scanner/comic_scanner.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;

class MockComicScannerService extends Mock implements ComicScannerService {}

void main() {
  late MockComicScannerService mockScanner;
  late CoverRepairService repairService;
  late Directory tempDir;

  setUp(() {
    mockScanner = MockComicScannerService();
    repairService = CoverRepairService(scannerService: mockScanner);
  });

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('cover_repair_test_');
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('repairSingle', () {
    test('does not call scanPath when cover file exists', () async {
      final coverFile = File(p.join(tempDir.path, 'cover.jpg'));
      await coverFile.writeAsBytes([1, 2, 3]);
      final candidate = CoverRepairCandidate(
        comicId: 'c1',
        coverUrl: coverFile.path,
        sourcePath: '/any.cbz',
      );

      await repairService.repairSingle(candidate);

      verifyNever(() => mockScanner.scanPath(any()));
    });

    test('does not call scanPath when coverUrl is null', () async {
      final candidate = CoverRepairCandidate(
        comicId: 'c1',
        coverUrl: null,
        sourcePath: '/any.cbz',
      );

      await repairService.repairSingle(candidate);

      verifyNever(() => mockScanner.scanPath(any()));
    });

    test('does not call scanPath when coverUrl is empty', () async {
      final candidate = CoverRepairCandidate(
        comicId: 'c1',
        coverUrl: '',
        sourcePath: '/any.cbz',
      );

      await repairService.repairSingle(candidate);

      verifyNever(() => mockScanner.scanPath(any()));
    });

    test('does not call scanPath when sourcePath is null', () async {
      final candidate = CoverRepairCandidate(
        comicId: 'c1',
        coverUrl: '/nonexistent/cover.jpg',
        sourcePath: null,
      );

      await repairService.repairSingle(candidate);

      verifyNever(() => mockScanner.scanPath(any()));
    });

    test('does not call scanPath when sourcePath is empty', () async {
      final candidate = CoverRepairCandidate(
        comicId: 'c1',
        coverUrl: '/nonexistent/cover.jpg',
        sourcePath: '',
      );

      await repairService.repairSingle(candidate);

      verifyNever(() => mockScanner.scanPath(any()));
    });

    test('does not call scanPath when sourcePath extension is not repairable', () async {
      final candidate = CoverRepairCandidate(
        comicId: 'c1',
        coverUrl: '/nonexistent/cover.jpg',
        sourcePath: '/a/b.txt',
      );

      await repairService.repairSingle(candidate);

      verifyNever(() => mockScanner.scanPath(any()));
    });

    test('does not call scanPath when sourcePath is .cbz but file does not exist', () async {
      final candidate = CoverRepairCandidate(
        comicId: 'c1',
        coverUrl: '/nonexistent/cover.jpg',
        sourcePath: p.join(tempDir.path, 'missing.cbz'),
      );

      await repairService.repairSingle(candidate);

      verifyNever(() => mockScanner.scanPath(any()));
    });

    test('calls scanPath when cover missing and sourcePath is existing .cbz', () async {
      final imageBytes = <int>[1, 2, 3];
      final archive = Archive()
        ..addFile(ArchiveFile('1.jpg', imageBytes.length, imageBytes));
      final zipBytes = ZipEncoder().encode(archive);
      final cbzFile = File(p.join(tempDir.path, 'comic.cbz'));
      await cbzFile.writeAsBytes(zipBytes!);

      when(() => mockScanner.scanPath(any())).thenAnswer((_) async => null);

      final candidate = CoverRepairCandidate(
        comicId: 'c1',
        coverUrl: '/nonexistent/cover.jpg',
        sourcePath: cbzFile.path,
      );

      await repairService.repairSingle(candidate);

      verify(() => mockScanner.scanPath(cbzFile.path)).called(1);
    });
  });
}
