import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_entry.dart';
import 'package:hentai_library/features/series/presentation/views/series_detail/series_detail_view_object.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/comic.dart';
import 'package:hentai_library/shared/domain/models/entity/comic/series.dart';
import 'package:hentai_library/shared/domain/models/enums.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_comic_page_item.dart';
import 'package:hentai_library/shared/domain/models/value_objects/series_comics_metadata.dart';

Comic _comic(String id, String title) {
  return Comic(
    comicId: id,
    path: '/lib/$id.zip',
    resourceType: ResourceType.zip,
    resourceSize: 1,
    createdAt: DateTime.utc(2026),
    lastUpdatedAt: DateTime.utc(2026),
    title: title,
    pageCount: 10,
  );
}

void main() {
  group('seriesDetailEntry', () {
    test('maps series and current page only', () {
      final Series series = Series(
        id: 's1',
        name: '系列甲',
        folderPath: '/lib/s1',
        serializationStatus: SerializationStatus.hiatus,
        totalCount: 5,
      );
      final entry = seriesDetailEntry(
        series: series,
        cover: const SizedBox(),
        metadata: const SeriesComicsMetadata(
          authors: <String>['作者'],
          tags: <String>['tag'],
          hasR18: true,
          languages: <String>['English'],
        ),
        pageItems: <SeriesComicPageItem>[
          (comic: _comic('c2', '第二话'), sortOrder: 2, sortOrderLocked: false),
        ],
        page: 2,
        pageSize: 20,
      );

      expect(entry.title, '系列甲');
      expect(entry.serializationStatus, SeriesSerializationStatus.hiatus);
      expect(entry.languages, <String>['English']);
      expect(entry.authors, <String>['作者']);
      expect(entry.tags, <String>['tag']);
      expect(entry.showAgeRestrictionChip, isTrue);
      expect(entry.showMetadataBlock, isTrue);
      expect(entry.volumeTotal, 5);
      expect(entry.comics.map((SeriesDetailComicItem c) => c.title), <String>[
        '第二话',
      ]);
      expect(entry.initialPage, 2);
      expect(entry.initialPageSize, 20);
    });

    test('hides metadata block when metadata is absent', () {
      final Series series = Series(
        id: 's2',
        name: '系列乙',
        folderPath: '/lib/s2',
      );
      final entry = seriesDetailEntry(
        series: series,
        cover: const SizedBox(),
        metadata: null,
        pageItems: const <SeriesComicPageItem>[],
        page: 1,
        pageSize: 20,
      );

      expect(entry.showMetadataBlock, isFalse);
      expect(entry.comics, isEmpty);
      expect(entry.serializationStatus, SeriesSerializationStatus.unknown);
    });
  });
}
