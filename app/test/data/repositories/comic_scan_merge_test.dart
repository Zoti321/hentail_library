import 'package:hentai_library/data/repositories/comic_scan_merge.dart';
import 'package:hentai_library/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:test/test.dart';

Comic _inputComic({
  required String path,
  required ResourceType resourceType,
  int? pageCount,
}) {
  return Comic(
    comicId: 'c1',
    path: path,
    resourceType: resourceType,
    title: 'Test',
    pageCount: pageCount,
  );
}

void main() {
  group('mergeKeptScanWithExisting', () {
    test('backfills pageCount when existing value is null', () {
      final Comic existing = _inputComic(
        path: '/comics/a.zip',
        resourceType: ResourceType.zip,
        pageCount: null,
      );
      final Comic scanned = _inputComic(
        path: '/comics/a.zip',
        resourceType: ResourceType.zip,
        pageCount: 12,
      );
      final Comic actual = mergeKeptScanWithExisting(scanned, existing);
      expect(actual.pageCount, 12);
    });

    test('preserves existing pageCount when source unchanged', () {
      final Comic existing = _inputComic(
        path: '/comics/a.zip',
        resourceType: ResourceType.zip,
        pageCount: 8,
      );
      final Comic scanned = _inputComic(
        path: '/comics/a.zip',
        resourceType: ResourceType.zip,
        pageCount: 12,
      );
      final Comic actual = mergeKeptScanWithExisting(scanned, existing);
      expect(actual.pageCount, 8);
    });

    test('overwrites pageCount when path changes', () {
      final Comic existing = _inputComic(
        path: '/comics/old.zip',
        resourceType: ResourceType.zip,
        pageCount: 8,
      );
      final Comic scanned = _inputComic(
        path: '/comics/new.zip',
        resourceType: ResourceType.zip,
        pageCount: 15,
      );
      final Comic actual = mergeKeptScanWithExisting(scanned, existing);
      expect(actual.path, '/comics/new.zip');
      expect(actual.pageCount, 15);
    });

    test('overwrites pageCount when resource type changes', () {
      final Comic existing = _inputComic(
        path: '/comics/a.zip',
        resourceType: ResourceType.zip,
        pageCount: 8,
      );
      final Comic scanned = _inputComic(
        path: '/comics/a.zip',
        resourceType: ResourceType.cbz,
        pageCount: 20,
      );
      final Comic actual = mergeKeptScanWithExisting(scanned, existing);
      expect(actual.resourceType, ResourceType.cbz);
      expect(actual.pageCount, 20);
    });
  });
}
