import 'package:hentai_library/features/library_browse/presentation/browse/models/browse_vo_mappers.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:test/test.dart';

void main() {
  test('comicBrowseVoFromComic keeps card fields only', () {
    final DateTime now = DateTime.utc(2026, 1, 1);
    final Comic comic = Comic(
      comicId: 'c1',
      path: '/c1',
      resourceType: ResourceType.zip,
      resourceSize: 1,
      createdAt: now,
      lastUpdatedAt: now,
      title: 'Title',
      pageCount: 12,
    );

    final vo = comicBrowseVoFromComic(comic);
    expect(vo.comicId, 'c1');
    expect(vo.title, 'Title');
    expect(vo.pageCount, 12);
    expect(vo.path, '/c1');
  });

  test('seriesBrowseVoFromSeries uses items.length as volumeCount', () {
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

    final vo = seriesBrowseVoFromSeries(series);
    expect(vo.id, 's1');
    expect(vo.name, 'Alpha');
    expect(vo.volumeCount, 2);
  });
}
