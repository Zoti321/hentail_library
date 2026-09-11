import 'package:flutter_rust_bridge/flutter_rust_bridge_for_generated.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/adapters/series_frb_mapper.dart';
import 'package:hentai_library/domain/library/library_series_projection.dart';
import 'package:hentai_library/domain/library/library_series_sort_option.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:hentai_library/domain/models/value_objects/paged_result.dart';
import 'package:hentai_library/domain/models/value_objects/series_comics_metadata.dart';
import 'package:hentai_library/domain/reading/series_reading_context.dart';
import 'package:hentai_library/src/rust/api/series.dart' as rust_series;

void main() {
  test('mapRustSeries maps Series DTO including locks and items', () {
    const rust_series.SeriesDto dto = rust_series.SeriesDto(
      seriesId: 's1',
      folderPath: '/lib/series-a',
      name: 'Series A',
      serializationStatus: 'ongoing',
      totalCount: 12,
      locks: rust_series.SeriesMetaLocksDto(
        name: true,
        serializationStatus: false,
        totalCount: true,
      ),
      items: <rust_series.SeriesItemDto>[
        rust_series.SeriesItemDto(
          seriesId: 's1',
          comicId: 'c1',
          sortOrder: 1.5,
          sortOrderLocked: true,
        ),
      ],
    );

    final Series mapped = mapRustSeries(dto);

    expect(mapped.id, 's1');
    expect(mapped.name, 'Series A');
    expect(mapped.folderPath, '/lib/series-a');
    expect(mapped.serializationStatus, SerializationStatus.ongoing);
    expect(mapped.totalCount, 12);
    expect(mapped.locks.name, isTrue);
    expect(mapped.locks.serializationStatus, isFalse);
    expect(mapped.locks.totalCount, isTrue);
    expect(mapped.items, hasLength(1));
    expect(mapped.items.single.comicId, 'c1');
    expect(mapped.items.single.order, 1.5);
    expect(mapped.items.single.sortOrderLocked, isTrue);
  });

  test(
    'mapRustSeries treats unknown serializationStatus and null totalCount',
    () {
      const rust_series.SeriesDto dto = rust_series.SeriesDto(
        seriesId: 's2',
        folderPath: '/x',
        name: 'X',
        serializationStatus: 'weird',
        locks: rust_series.SeriesMetaLocksDto(
          name: false,
          serializationStatus: false,
          totalCount: false,
        ),
        items: <rust_series.SeriesItemDto>[],
      );

      final Series mapped = mapRustSeries(dto);
      expect(mapped.serializationStatus, SerializationStatus.unknown);
      expect(mapped.totalCount, isNull);
      expect(mapped.items, isEmpty);
    },
  );

  test('mapRustSeriesItem maps order and lock flag', () {
    const rust_series.SeriesItemDto dto = rust_series.SeriesItemDto(
      seriesId: 's1',
      comicId: 'c9',
      sortOrder: 0,
      sortOrderLocked: false,
    );

    final SeriesItem item = mapRustSeriesItem(dto);
    expect(item.comicId, 'c9');
    expect(item.order, 0);
    expect(item.sortOrderLocked, isFalse);
  });

  test('mapRustSeriesReadingContext copies ordered comic ids', () {
    const rust_series.SeriesReadingContextDto dto =
        rust_series.SeriesReadingContextDto(
          seriesId: 's1',
          seriesName: 'Series',
          orderedComicIds: <String>['a', 'b'],
          currentIndex: 1,
        );

    final SeriesReadingContext ctx = mapRustSeriesReadingContext(dto);
    expect(ctx.seriesId, 's1');
    expect(ctx.seriesName, 'Series');
    expect(ctx.orderedComicIds, <String>['a', 'b']);
    expect(ctx.currentIndex, 1);
  });

  test('mapRustSeriesComicsMetadata maps facet lists and hasR18', () {
    const rust_series.SeriesComicsMetadataDto dto =
        rust_series.SeriesComicsMetadataDto(
          authors: <String>['Alice'],
          tags: <String>['tag'],
          hasR18: true,
          languages: <String>['zh'],
          parodies: <String>['p'],
          characters: <String>['c'],
        );

    final SeriesComicsMetadata meta = mapRustSeriesComicsMetadata(dto);
    expect(meta.authors, <String>['Alice']);
    expect(meta.tags, <String>['tag']);
    expect(meta.hasR18, isTrue);
    expect(meta.languages, <String>['zh']);
    expect(meta.parodies, <String>['p']);
    expect(meta.characters, <String>['c']);
  });

  test('mapLibrarySeriesFilter forwards Series list filter fields', () {
    const LibrarySeriesFilter filter = LibrarySeriesFilter(
      showR18: true,
      r18Only: false,
      query: 'foo',
      requireItems: false,
      serializationStatus: 'ongoing',
      preferLibraryRootSeries: false,
    );

    final rust_series.SeriesFilterDto mapped = mapLibrarySeriesFilter(filter);
    expect(mapped.showR18, isTrue);
    expect(mapped.r18Only, isFalse);
    expect(mapped.query, 'foo');
    expect(mapped.requireItems, isFalse);
    expect(mapped.serializationStatus, 'ongoing');
    expect(mapped.preferLibraryRootSeries, isFalse);
    expect(mapped.libraryId, isNull);
  });

  test('mapSeriesSortOption maps each Series sort field', () {
    expect(
      mapSeriesSortOption(
        sortOption: const LibrarySeriesSortOption(
          field: LibrarySeriesSortField.name,
          descending: true,
        ),
      ),
      const rust_series.SeriesSortOptionDto(
        field: rust_series.SeriesSortFieldDto.name,
        descending: true,
      ),
    );
    expect(
      mapSeriesSortOption(
        sortOption: const LibrarySeriesSortOption(
          field: LibrarySeriesSortField.comicCount,
        ),
      ).field,
      rust_series.SeriesSortFieldDto.comicCount,
    );
    expect(
      mapSeriesSortOption(
        sortOption: const LibrarySeriesSortOption(
          field: LibrarySeriesSortField.random,
        ),
      ).field,
      rust_series.SeriesSortFieldDto.random,
    );
  });

  test('mapPagedSeriesResult maps page of Series', () {
    final rust_series.PagedSeriesResultDto page =
        rust_series.PagedSeriesResultDto(
          items: const <rust_series.SeriesDto>[
            rust_series.SeriesDto(
              seriesId: 's1',
              folderPath: '/a',
              name: 'A',
              serializationStatus: 'ended',
              locks: rust_series.SeriesMetaLocksDto(
                name: false,
                serializationStatus: false,
                totalCount: false,
              ),
              items: <rust_series.SeriesItemDto>[],
            ),
          ],
          totalCount: PlatformInt64Util.from(3),
          page: 0,
          pageSize: 20,
        );

    final PagedResult<Series> mapped = mapPagedSeriesResult(page);
    expect(mapped.items.single.id, 's1');
    expect(mapped.items.single.serializationStatus, SerializationStatus.ended);
    expect(mapped.totalCount, 3);
    expect(mapped.page, 0);
    expect(mapped.pageSize, 20);
  });

  test('mapSeriesPageRequest maps PageRequest', () {
    final mapped = mapSeriesPageRequest((page: 1, pageSize: 40));
    expect(mapped.page, 1);
    expect(mapped.pageSize, 40);
  });

  test('mapUpdateSeriesUserMeta maps locks payload and clearTotalCount', () {
    final rust_series.UpdateSeriesUserMetaDto dto = mapUpdateSeriesUserMeta(
      name: 'Renamed',
      serializationStatus: SerializationStatus.hiatus,
      totalCount: 8,
      clearTotalCount: true,
    );

    expect(dto.name, 'Renamed');
    expect(dto.serializationStatus, 'hiatus');
    expect(dto.totalCount, 8);
    expect(dto.clearTotalCount, isTrue);
  });
}
