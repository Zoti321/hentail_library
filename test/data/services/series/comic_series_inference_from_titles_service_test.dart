import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/data/services/series/comic_series_inference_from_titles_service.dart';

void main() {
  const ComicSeriesInferenceFromTitlesService service =
      ComicSeriesInferenceFromTitlesService();

  test('groups by base name and sorts by volume then comicId', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(<ComicTitleInput>[
      ComicTitleInput(comicId: 'b', title: '标题A 2'),
      ComicTitleInput(comicId: 'a', title: '标题A 1'),
      ComicTitleInput(comicId: 'c', title: '标题A 3'),
    ]);
    expect(actual.length, 1);
    expect(actual.first.seriesName, '标题A');
    expect(
      actual.first.entries.map((e) => e.comicId).toList(),
      <String>['a', 'b', 'c'],
    );
    expect(actual.first.entries.map((e) => e.volumeIndex).toList(), <int>[
      1,
      2,
      3,
    ]);
  });

  test('requires at least two comics per base name', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(<ComicTitleInput>[
      ComicTitleInput(comicId: 'x', title: 'Only 1'),
    ]);
    expect(actual, isEmpty);
  });

  test('ignores titles without trailing digit segment', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(<ComicTitleInput>[
      ComicTitleInput(comicId: 'a', title: 'NoNumber'),
      ComicTitleInput(comicId: 'b', title: 'Foo 1a'),
    ]);
    expect(actual, isEmpty);
  });

  test('trims base name and rejects volume zero', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(<ComicTitleInput>[
      ComicTitleInput(comicId: 'a', title: '  标题A  0  '),
      ComicTitleInput(comicId: 'b', title: '标题A 1'),
    ]);
    expect(actual, isEmpty);
  });

  test('stable order for same volume uses comicId', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(<ComicTitleInput>[
      ComicTitleInput(comicId: 'z', title: 'S 1'),
      ComicTitleInput(comicId: 'm', title: 'S 1'),
    ]);
    expect(actual.length, 1);
    expect(actual.first.entries.map((e) => e.comicId).toList(), <String>[
      'm',
      'z',
    ]);
  });

  test('multiple series names sort lexically in output', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(<ComicTitleInput>[
      ComicTitleInput(comicId: 'b', title: 'B 1'),
      ComicTitleInput(comicId: 'c', title: 'B 2'),
      ComicTitleInput(comicId: 'd', title: 'A 1'),
      ComicTitleInput(comicId: 'e', title: 'A 2'),
    ]);
    expect(actual.map((g) => g.seriesName).toList(), <String>['A', 'B']);
  });

  test('groups 前篇 before 后篇 under same series name', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(<ComicTitleInput>[
      ComicTitleInput(comicId: 'k', title: '标题A 后篇'),
      ComicTitleInput(comicId: 'z', title: '标题A 前篇'),
    ]);
    expect(actual.length, 1);
    expect(actual.first.seriesName, '标题A');
    expect(actual.first.entries.map((e) => e.comicId).toList(), <String>[
      'z',
      'k',
    ]);
    expect(actual.first.entries.map((e) => e.volumeIndex).toList(), <int>[1, 2]);
  });
}
