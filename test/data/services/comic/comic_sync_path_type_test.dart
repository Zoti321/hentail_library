import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/core/util/comic_file_types.dart';
import 'package:hentai_library/domain/enums/enums.dart';

void main() {
  group('scannedItemTypeFromPath', () {
    test('returns epub for .epub path', () {
      expect(
        scannedItemTypeFromPath('/a/b.epub'),
        ScannedItemType.epub,
      );
    });

    test('returns archive for .cbz path', () {
      expect(
        scannedItemTypeFromPath('/a/b.cbz'),
        ScannedItemType.archive,
      );
    });

    test('returns archive for .zip path', () {
      expect(
        scannedItemTypeFromPath('/a/b.zip'),
        ScannedItemType.archive,
      );
    });

    test('returns archive for .cbr path', () {
      expect(
        scannedItemTypeFromPath('/a/b.cbr'),
        ScannedItemType.archive,
      );
    });

    test('returns archive for .rar path', () {
      expect(
        scannedItemTypeFromPath('/a/b.rar'),
        ScannedItemType.archive,
      );
    });

    test('returns folder for path without extension', () {
      expect(
        scannedItemTypeFromPath('/a/b'),
        ScannedItemType.folder,
      );
    });

    test('returns folder for .txt path', () {
      expect(
        scannedItemTypeFromPath('/a/b.txt'),
        ScannedItemType.folder,
      );
    });

    test('returns archive for uppercase .CBZ extension', () {
      expect(
        scannedItemTypeFromPath('/a/b.CBZ'),
        ScannedItemType.archive,
      );
    });

    test('returns archive for mixed case .Zip extension', () {
      expect(
        scannedItemTypeFromPath('/a/b.Zip'),
        ScannedItemType.archive,
      );
    });
  });
}
