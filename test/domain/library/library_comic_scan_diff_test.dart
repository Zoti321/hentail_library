import 'package:hentai_library/domain/entity/comic/comic.dart';
import 'package:hentai_library/domain/library/library_comic_scan_diff.dart';
import 'package:hentai_library/data/services/comic/resource_types.dart';
import 'package:hentai_library/domain/enums/enums.dart';
import 'package:hentai_library/domain/entity/comic/tag.dart';
import 'package:test/test.dart';

void main() {
  group('library_comic_scan_diff', () {
    test('dedupeScannedByComicId 后者覆盖前者', () {
      final a = Comic(
        comicId: 'x',
        path: r'C:\a',
        resourceType: ResourceType.dir,
        title: 'first',
      );
      final b = Comic(
        comicId: 'x',
        path: r'C:\b',
        resourceType: ResourceType.zip,
        title: 'second',
      );
      final m = dedupeScannedByComicId([a, b]);
      expect(m.length, 1);
      expect(m['x']!.path, r'C:\b');
      expect(m['x']!.resourceType, ResourceType.zip);
    });

    test('computeLibraryComicScanIdDiff 空扫描清空全部', () {
      final d = computeLibraryComicScanIdDiff(
        existingIds: {'a', 'b'},
        scannedIds: {},
      );
      expect(d.removedIds, {'a', 'b'});
      expect(d.addedIds, isEmpty);
      expect(d.keptIds, isEmpty);
    });

    test('computeLibraryComicScanIdDiff 全新增', () {
      final d = computeLibraryComicScanIdDiff(
        existingIds: {},
        scannedIds: {'x', 'y'},
      );
      expect(d.removedIds, isEmpty);
      expect(d.addedIds, {'x', 'y'});
      expect(d.keptIds, isEmpty);
    });

    test('mergeKeptScanWithExisting 保留标题与标签', () {
      final scanned = Comic(
        comicId: 'c1',
        path: r'D:\new\path',
        resourceType: ResourceType.cbz,
        title: 'parsed',
        authors: ['p'],
      );
      final existing = Comic(
        comicId: 'c1',
        path: r'C:\old',
        resourceType: ResourceType.dir,
        title: 'user',
        authors: ['u'],
        contentRating: ContentRating.safe,
        tags: [Tag(name: 't1')],
      );
      final m = mergeKeptScanWithExisting(scanned, existing);
      expect(m.path, r'D:\new\path');
      expect(m.resourceType, ResourceType.cbz);
      expect(m.title, 'user');
      expect(m.authors, ['u']);
      expect(m.contentRating, ContentRating.safe);
      expect(m.tags.map((e) => e.name).toList(), ['t1']);
    });
  });
}
