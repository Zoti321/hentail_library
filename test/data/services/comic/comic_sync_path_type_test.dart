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

    test('returns cbz for .cbz path', () {
      expect(
        scannedItemTypeFromPath('/a/b.cbz'),
        ScannedItemType.cbz,
      );
    });

    test('returns zip for .zip path', () {
      expect(
        scannedItemTypeFromPath('/a/b.zip'),
        ScannedItemType.zip,
      );
    });

    test('returns zip for .cbr path', () {
      expect(
        scannedItemTypeFromPath('/a/b.cbr'),
        ScannedItemType.zip,
      );
    });

    test('returns zip for .rar path', () {
      expect(
        scannedItemTypeFromPath('/a/b.rar'),
        ScannedItemType.zip,
      );
    });

    test('returns dir for path without extension', () {
      expect(
        scannedItemTypeFromPath('/a/b'),
        ScannedItemType.dir,
      );
    });

    test('returns dir for .txt path', () {
      expect(
        scannedItemTypeFromPath('/a/b.txt'),
        ScannedItemType.dir,
      );
    });

    test('returns cbz for uppercase .CBZ extension', () {
      expect(
        scannedItemTypeFromPath('/a/b.CBZ'),
        ScannedItemType.cbz,
      );
    });

    test('returns zip for mixed case .Zip extension', () {
      expect(
        scannedItemTypeFromPath('/a/b.Zip'),
        ScannedItemType.zip,
      );
    });
  });
}
