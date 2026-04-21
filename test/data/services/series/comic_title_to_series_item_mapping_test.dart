import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/series/comic_title_to_series_item_mapping.dart';

void main() {
  const ComicTitleToSeriesItemMapping mapping =
      ComicTitleToSeriesItemMapping();

  test('mapComicTitleToSeriesVolume parses base and volume', () {
    final MappedSeriesVolume? actual =
        mapping.mapComicTitleToSeriesVolume('标题A 3');
    expect(actual, isNotNull);
    expect(actual!.seriesName, '标题A');
    expect(actual.volumeSortKey, 3);
  });

  test('mapComicTitleToSeriesVolume returns null for invalid patterns', () {
    expect(mapping.mapComicTitleToSeriesVolume('NoDigit'), isNull);
    expect(mapping.mapComicTitleToSeriesVolume('X 0'), isNull);
  });

  test('mapComicTitleToSeriesVolume maps 前篇 and 后篇 to volumes 1 and 2', () {
    final MappedSeriesVolume? zen =
        mapping.mapComicTitleToSeriesVolume('标题A 前篇');
    final MappedSeriesVolume? kou =
        mapping.mapComicTitleToSeriesVolume('标题A 后篇');
    expect(zen, isNotNull);
    expect(zen!.seriesName, '标题A');
    expect(zen.volumeSortKey, 1);
    expect(kou, isNotNull);
    expect(kou!.seriesName, '标题A');
    expect(kou.volumeSortKey, 2);
  });

  test('digit suffix takes precedence over substring false positives', () {
    final MappedSeriesVolume? actual =
        mapping.mapComicTitleToSeriesVolume('X 前篇 1');
    expect(actual, isNotNull);
    expect(actual!.seriesName, 'X 前篇');
    expect(actual.volumeSortKey, 1);
  });

  test('contiguous base plus index without whitespace', () {
    final MappedSeriesVolume? actual =
        mapping.mapComicTitleToSeriesVolume('标题A12');
    expect(actual, isNotNull);
    expect(actual!.seriesName, '标题A');
    expect(actual.volumeSortKey, 12);
  });

  test('rejects base whose last two chars are both digits', () {
    expect(mapping.mapComicTitleToSeriesVolume('12 3'), isNull);
    expect(mapping.mapComicTitleToSeriesVolume('1234'), isNull);
  });

  test('contiguous form not used when space before trailing digits', () {
    expect(
      mapping.mapComicTitleToSeriesVolume('标题A 12')?.seriesName,
      '标题A',
    );
    expect(mapping.mapComicTitleToSeriesVolume('标题A 12')?.volumeSortKey, 12);
  });

  test('strips leading Comic Market (C###) tags from series base', () {
    final MappedSeriesVolume? actual =
        mapping.mapComicTitleToSeriesVolume('(C78) 标题A 3');
    expect(actual, isNotNull);
    expect(actual!.seriesName, '标题A');
    expect(actual.volumeSortKey, 3);
  });

  test('strips multiple leading (C###) tags', () {
    final MappedSeriesVolume? actual =
        mapping.mapComicTitleToSeriesVolume('(C78)(C79) 标题A 2');
    expect(actual, isNotNull);
    expect(actual!.seriesName, '标题A');
    expect(actual.volumeSortKey, 2);
  });

  test('Comic Market tag examples map without C### in series name', () {
    expect(
      mapping.mapComicTitleToSeriesVolume('(C78) C2lemon 1')?.seriesName,
      'C2lemon',
    );
    expect(
      mapping.mapComicTitleToSeriesVolume('(C86) C2lemon@EX'),
      isNull,
    );
  });

  test('only leading (C###) is stripped; mid-title (C78) stays in base', () {
    final MappedSeriesVolume? actual =
        mapping.mapComicTitleToSeriesVolume('A (C78) B 1');
    expect(actual, isNotNull);
    expect(actual!.seriesName, 'A (C78) B');
    expect(actual.volumeSortKey, 1);
  });

  test('title with only Comic Market tag maps to null', () {
    expect(mapping.mapComicTitleToSeriesVolume('(C78)'), isNull);
    expect(mapping.mapComicTitleToSeriesVolume('  (C88)  '), isNull);
  });
}
