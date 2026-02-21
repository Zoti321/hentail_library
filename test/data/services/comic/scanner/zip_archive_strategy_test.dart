import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/scanner/comic_scanner.dart';
import 'package:path/path.dart' as p;

void main() {
  late ZipArchiveStrategy strategy;
  late Directory tempDir;

  setUp(() {
    strategy = ZipArchiveStrategy();
  });

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('zip_archive_test_');
  });

  tearDownAll(() async {
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  group('canHandle', () {
    test('returns true for File with .cbz extension', () {
      final file = File(p.join(tempDir.path, 'x.cbz'));
      expect(strategy.canHandle(file), isTrue);
    });

    test('returns true for File with .zip extension', () {
      final file = File(p.join(tempDir.path, 'x.zip'));
      expect(strategy.canHandle(file), isTrue);
    });

    test('returns false for File with .rar extension', () {
      final file = File(p.join(tempDir.path, 'x.rar'));
      expect(strategy.canHandle(file), isFalse);
    });

    test('returns false for Directory', () {
      expect(strategy.canHandle(tempDir), isFalse);
    });
  });

  group('validate', () {
    test('returns true for zip containing one image entry', () async {
      final imageBytes = <int>[1, 2, 3];
      final archive = Archive()
        ..addFile(ArchiveFile('1.jpg', imageBytes.length, imageBytes));
      final zipBytes = ZipEncoder().encode(archive);
      expect(zipBytes, isNotNull);
      final zipFile = File(p.join(tempDir.path, 'valid.cbz'));
      await zipFile.writeAsBytes(zipBytes!);
      expect(await strategy.validate(zipFile), isTrue);
    });

    test('returns false for zip with no image entries', () async {
      final data = <int>[0];
      final archive = Archive()
        ..addFile(ArchiveFile('readme.txt', data.length, data));
      final zipBytes = ZipEncoder().encode(archive);
      expect(zipBytes, isNotNull);
      final zipFile = File(p.join(tempDir.path, 'no_image.zip'));
      await zipFile.writeAsBytes(zipBytes!);
      expect(await strategy.validate(zipFile), isFalse);
    });

    test('returns false for non-zip file', () async {
      final txtFile = File(p.join(tempDir.path, 'fake.zip'));
      await txtFile.writeAsString('not a zip');
      expect(await strategy.validate(txtFile), isFalse);
    });
  });

  group('getMetadata', () {
    test('returns title and pageCount for zip with one image', () async {
      final imageBytes = <int>[1, 2, 3];
      final archive = Archive()
        ..addFile(ArchiveFile('1.jpg', imageBytes.length, imageBytes));
      final zipBytes = ZipEncoder().encode(archive);
      expect(zipBytes, isNotNull);
      final zipFile = File(p.join(tempDir.path, 'meta_test.cbz'));
      await zipFile.writeAsBytes(zipBytes!);

      final metadata = await strategy.getMetadata(zipFile);
      expect(metadata.title, p.basenameWithoutExtension(zipFile.path));
      expect(metadata.pageCount, 1);
    });
  });

  group('getCoverBytes', () {
    test('returns first image bytes for zip with one image', () async {
      final imageBytes = <int>[1, 2, 3];
      final archive = Archive()
        ..addFile(ArchiveFile('1.jpg', imageBytes.length, imageBytes));
      final zipBytes = ZipEncoder().encode(archive);
      expect(zipBytes, isNotNull);
      final zipFile = File(p.join(tempDir.path, 'cover_test.zip'));
      await zipFile.writeAsBytes(zipBytes!);

      final coverBytes = await strategy.getCoverBytes(zipFile);
      expect(coverBytes, isNotNull);
      expect(coverBytes, Uint8List.fromList(imageBytes));
    });
  });
}
