import 'package:hentai_library/features/library_browse/presentation/browse/models/browse_view_object_mappers.dart';
import 'package:hentai_library/features/comic/public/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:test/test.dart';

void main() {
  test('comicBrowseViewObjectFromComic keeps card fields only', () {
    final DateTime now = DateTime.utc(2026, 1, 1);
    final Comic comic = Comic.restore(
      comicId: 'c1',
      path: '/c1',
      resourceType: ResourceType.zip,
      resourceSize: 1,
      createdAt: now,
      lastUpdatedAt: now,
      title: 'Title',
      pageCount: 12,
    );

    final viewObject = comicBrowseViewObjectFromComic(comic);
    expect(viewObject.comicId, 'c1');
    expect(viewObject.title, 'Title');
    expect(viewObject.pageCount, 12);
    expect(viewObject.path, '/c1');
  });

  test('seriesBrowseViewObjectFromSeries uses items.length as volumeCount', () {
    final Series series = Series(
      id: 's1',
      name: 'Alpha',
      folderPath: '/alpha',
      totalCount: 99,
      items: <SeriesItem>[
        SeriesItem(comicId: 'c1', order: 1),
        SeriesItem(comicId: 'c2', order: 2),
      ],
    );

    final viewObject = seriesBrowseViewObjectFromSeries(series);
    expect(viewObject.id, 's1');
    expect(viewObject.name, 'Alpha');
    expect(viewObject.volumeCount, 2);
  });
}
