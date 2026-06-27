import 'package:hentai_library/domain/library/library_comic_projection.dart';
import 'package:hentai_library/domain/models/entity/comic/series.dart';
import 'package:hentai_library/domain/models/entity/comic/series_item.dart';
import 'package:hentai_library/domain/models/enums.dart';
import 'package:test/test.dart';

void main() {
  const LibraryComicProjection projection = LibraryComicProjection();

  group('LibraryComicProjection', () {
    test('showR18 inverts Healthy mode', () {
      expect(projection.showR18(isHealthyMode: true), isFalse);
      expect(projection.showR18(isHealthyMode: false), isTrue);
    });

    test('collectComicIdsInAnySeries flattens series items', () {
      final List<Series> inputSeries = <Series>[
        Series(
          name: 'A',
          items: <SeriesItem>[
            SeriesItem(comicId: 'c1', order: 1),
            SeriesItem(comicId: 'c2', order: 2),
          ],
        ),
        Series(
          name: 'B',
          items: <SeriesItem>[
            SeriesItem(comicId: 'c2', order: 1),
          ],
        ),
      ];
      expect(
        projection.collectComicIdsInAnySeries(inputSeries),
        <String>{'c1', 'c2'},
      );
    });

    test('buildListFilter applies Healthy mode and series exclusion', () {
      final filter = projection.buildListFilter(
        displayTarget: LibraryDisplayTarget.comics,
        isHealthyMode: true,
        hideComicsInSeries: true,
        comicIdsInAnySeries: <String>{'in-series'},
      );
      expect(filter.showR18, isFalse);
      expect(filter.displayTarget, LibraryDisplayTarget.comics);
      expect(filter.comicIdsExcludedBySeriesMembership, <String>{'in-series'});
    });

    test('buildListFilter skips series exclusion when setting off', () {
      final filter = projection.buildListFilter(
        displayTarget: LibraryDisplayTarget.all,
        isHealthyMode: false,
        hideComicsInSeries: false,
        comicIdsInAnySeries: <String>{'in-series'},
      );
      expect(filter.showR18, isTrue);
      expect(filter.comicIdsExcludedBySeriesMembership, isNull);
    });
  });
}
