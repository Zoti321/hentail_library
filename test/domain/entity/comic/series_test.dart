import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/domain/entity/comic/series.dart';
import 'package:hentai_library/domain/entity/comic/series_item.dart';

void main() {
  test('Series.coverItem is null when series has no items', () {
    final SeriesItem? actual = Series(
      name: 'empty',
      items: <SeriesItem>[],
    ).coverItem;
    expect(actual, isNull);
  });

  test('Series.coverItem returns the only item', () {
    final SeriesItem only = SeriesItem(comicId: 'c1', order: 0);
    final Series s = Series(name: 's', items: <SeriesItem>[only]);
    expect(s.coverItem, same(only));
  });

  test('Series.coverItem picks largest order', () {
    final SeriesItem low = SeriesItem(comicId: 'a', order: 1);
    final SeriesItem high = SeriesItem(comicId: 'b', order: 5);
    final Series s = Series(name: 's', items: <SeriesItem>[low, high]);
    expect(s.coverItem, same(high));
  });

  test('Series.coverItem breaks ties by smaller comicId', () {
    final SeriesItem b = SeriesItem(comicId: 'b', order: 3);
    final SeriesItem a = SeriesItem(comicId: 'a', order: 3);
    final Series s = Series(name: 's', items: <SeriesItem>[b, a]);
    expect(s.coverItem?.comicId, 'a');
  });
}
