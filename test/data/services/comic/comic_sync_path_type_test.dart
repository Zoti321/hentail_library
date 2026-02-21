import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/comic/comic_sync_service.dart';
import 'package:hentai_library/domain/enums/enums.dart';

void main() {
  group('ComicSyncService.typeFromPath', () {
    test('returns epub for .epub path', () {
      expect(
        ComicSyncService.typeFromPath('/a/b.epub'),
        ScannedItemType.epub,
      );
    });

    test('returns archive for .cbz path', () {
      expect(
        ComicSyncService.typeFromPath('/a/b.cbz'),
        ScannedItemType.archive,
      );
    });

    test('returns archive for .zip path', () {
      expect(
        ComicSyncService.typeFromPath('/a/b.zip'),
        ScannedItemType.archive,
      );
    });

    test('returns archive for .cbr path', () {
      expect(
        ComicSyncService.typeFromPath('/a/b.cbr'),
        ScannedItemType.archive,
      );
    });

    test('returns archive for .rar path', () {
      expect(
        ComicSyncService.typeFromPath('/a/b.rar'),
        ScannedItemType.archive,
      );
    });

    test('returns folder for path without extension', () {
      expect(
        ComicSyncService.typeFromPath('/a/b'),
        ScannedItemType.folder,
      );
    });

    test('returns folder for .txt path', () {
      expect(
        ComicSyncService.typeFromPath('/a/b.txt'),
        ScannedItemType.folder,
      );
    });

    test('returns archive for uppercase .CBZ extension', () {
      expect(
        ComicSyncService.typeFromPath('/a/b.CBZ'),
        ScannedItemType.archive,
      );
    });

    test('returns archive for mixed case .Zip extension', () {
      expect(
        ComicSyncService.typeFromPath('/a/b.Zip'),
        ScannedItemType.archive,
      );
    });
  });
}
