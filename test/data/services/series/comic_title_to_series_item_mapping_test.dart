import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/series/comic_title_to_series_item_mapping.dart';

void main() {
  const ComicTitleToSeriesItemMapping mapping =
      ComicTitleToSeriesItemMapping();

  test('mapComicTitleToSeriesVolume parses base and volume', () {
    final ({String seriesName, int volumeIndex})? actual =
        mapping.mapComicTitleToSeriesVolume('标题A 3');
    expect(actual, isNotNull);
    expect(actual!.seriesName, '标题A');
    expect(actual.volumeIndex, 3);
  });

  test('mapComicTitleToSeriesVolume returns null for invalid patterns', () {
    expect(mapping.mapComicTitleToSeriesVolume('NoDigit'), isNull);
    expect(mapping.mapComicTitleToSeriesVolume('X 0'), isNull);
  });

  test('mapComicTitleToSeriesVolume maps 前篇 and 后篇 to volumes 1 and 2', () {
    final ({String seriesName, int volumeIndex})? zen =
        mapping.mapComicTitleToSeriesVolume('标题A 前篇');
    final ({String seriesName, int volumeIndex})? kou =
        mapping.mapComicTitleToSeriesVolume('标题A 后篇');
    expect(zen, isNotNull);
    expect(zen!.seriesName, '标题A');
    expect(zen.volumeIndex, 1);
    expect(kou, isNotNull);
    expect(kou!.seriesName, '标题A');
    expect(kou.volumeIndex, 2);
  });

  test('digit suffix takes precedence over substring false positives', () {
    final ({String seriesName, int volumeIndex})? actual =
        mapping.mapComicTitleToSeriesVolume('X 前篇 1');
    expect(actual, isNotNull);
    expect(actual!.seriesName, 'X 前篇');
    expect(actual.volumeIndex, 1);
  });
}
