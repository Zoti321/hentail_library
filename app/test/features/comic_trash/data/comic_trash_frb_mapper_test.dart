import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/comic_trash/data/mappers/comic_trash_frb_mapper.dart';
import 'package:hentai_library/features/comic_trash/domain/trashed_comic.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/src/rust/api/comic_trash.dart' as rust;

void main() {
  rust.TrashedComicFrbDto trashed({required String kind}) {
    return rust.TrashedComicFrbDto(
      comicId: 'c1',
      path: '/lib/c1.cbz',
      resourceType: 'cbz',
      resourceSize: PlatformInt64Util.from(2048),
      createdAt: PlatformInt64Util.from(1700000000000),
      lastUpdatedAt: PlatformInt64Util.from(1700000600000),
      title: 'Title',
      pageCount: 12,
      deletedAt: PlatformInt64Util.from(1700001000000),
      libraryName: 'My Lib',
      libraryKind: kind,
    );
  }

  test(
    'mapTrashedComic maps summary comic, UTC deletedAt, library and kind',
    () {
      final TrashedComic local = mapTrashedComic(trashed(kind: 'local'));

      expect(local.comic.comicId, 'c1');
      expect(local.comic.title, 'Title');
      expect(local.comic.pageCount, 12);
      expect(local.comic.resourceType, ResourceType.cbz);
      expect(local.comic.authors, isEmpty);
      expect(
        local.deletedAt,
        DateTime.fromMillisecondsSinceEpoch(1700001000000, isUtc: true),
      );
      expect(local.libraryName, 'My Lib');
      expect(local.isRemote, isFalse);
      expect(mapTrashedComic(trashed(kind: 'remote')).isRemote, isTrue);
    },
  );

  test('mapTrashedComicsPage maps page envelope', () {
    final PagedResult<TrashedComic> page = mapTrashedComicsPage(
      rust.PagedTrashedComicResultFrbDto(
        items: <rust.TrashedComicFrbDto>[trashed(kind: 'remote')],
        totalCount: PlatformInt64Util.from(3),
        page: 1,
        pageSize: 50,
      ),
    );

    expect(page.items.single.isRemote, isTrue);
    expect(page.totalCount, 3);
    expect(page.page, 1);
    expect(page.pageSize, 50);
  });

  test('mapTrashedComicCounts and mapComicPurgeResult', () {
    final TrashedComicCounts counts = mapTrashedComicCounts(
      rust.TrashedComicCountsFrbDto(
        total: PlatformInt64Util.from(5),
        local: PlatformInt64Util.from(3),
        remote: PlatformInt64Util.from(2),
      ),
    );
    expect(counts, (total: 5, local: 3, remote: 2));

    final ComicPurgeResult result = mapComicPurgeResult(
      const rust.ComicPurgeResultFrbDto(
        succeeded: 2,
        failed: 1,
        errorSamples: <String>['boom'],
      ),
    );
    expect(result.succeeded, 2);
    expect(result.failed, 1);
    expect(result.errorSamples, <String>['boom']);
  });
}
