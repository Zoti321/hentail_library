import 'package:hentai_library/domain/models/value_objects/series_comics_metadata.dart';
import 'package:test/test.dart';

void main() {
  group('SeriesComicsMetadata.hasMetadataBlock', () {
    test('false when authors/tags/characters all empty', () {
      expect(
        const SeriesComicsMetadata(
          authors: <String>[],
          tags: <String>[],
          hasR18: false,
          languages: <String>['Japanese'],
          parodies: <String>['Fate'],
        ).hasMetadataBlock,
        isFalse,
      );
    });

    test('true when characters non-empty even if authors/tags empty', () {
      expect(
        const SeriesComicsMetadata(
          authors: <String>[],
          tags: <String>[],
          hasR18: false,
          characters: <String>['Saber'],
        ).hasMetadataBlock,
        isTrue,
      );
    });
  });
}
