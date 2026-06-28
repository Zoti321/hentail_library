import 'dart:io';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:hentai_library/data/services/comic/scan/comic_scan_parse_service.dart';
import 'package:hentai_library/data/services/comic/scan/resource_parser.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:test/test.dart';

ArchiveFile _zipFile(String name, List<int> content) {
  return ArchiveFile(name, content.length, content);
}

Future<File> _createTempZip(List<ArchiveFile> entries) async {
  final Archive archive = Archive();
  for (final ArchiveFile entry in entries) {
    archive.addFile(entry);
  }
  final List<int>? encoded = ZipEncoder().encode(archive);
  if (encoded == null) {
    throw StateError('zip encode failed');
  }
  final Directory dir = await Directory.systemTemp.createTemp('hl_zip_test_');
  final File file = File('${dir.path}/comic.zip');
  await file.writeAsBytes(Uint8List.fromList(encoded));
  return file;
}

void main() {
  group('parsePureImageZipArchive', () {
    test('counts image entries and skips non-images', () async {
      final File file = await _createTempZip(<ArchiveFile>[
        _zipFile('readme.txt', <int>[1, 2, 3]),
        _zipFile('01.jpg', <int>[1]),
        _zipFile('nested/02.png', <int>[1]),
        _zipFile('nested/subdir/', <int>[]),
      ]);
      final ParsedResource? actual = await parsePureImageZipArchive(
        file,
        ResourceType.zip,
        defaultComicParseContext(),
      );
      expect(actual, isNotNull);
      expect(actual!.meta.pageCount, 2);
      expect(actual.type, ResourceType.zip);
    });

    test('returns null when archive has no image entries', () async {
      final File file = await _createTempZip(<ArchiveFile>[
        _zipFile('readme.txt', <int>[1]),
        _zipFile('notes.md', <int>[2]),
      ]);
      final ParsedResource? actual = await parsePureImageZipArchive(
        file,
        ResourceType.cbz,
        defaultComicParseContext(),
      );
      expect(actual, isNull);
    });

    test('applies page count for cbz resource type', () async {
      final File file = await _createTempZip(<ArchiveFile>[
        _zipFile('page.webp', <int>[1]),
      ]);
      final ParsedResource? actual = await parsePureImageZipArchive(
        file,
        ResourceType.cbz,
        defaultComicParseContext(),
      );
      expect(actual, isNotNull);
      expect(actual!.type, ResourceType.cbz);
      expect(actual.meta.pageCount, 1);
    });
  });
}
