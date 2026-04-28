import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/services/series/auto_series_infer_service.dart';

void main() {
  const AutoSeriesInferService service = AutoSeriesInferService();

  test('groups by base name and sorts by volume then comicId', () {
    final List<InferredSeriesGroup> actual = service
        .inferGroups(<ComicTitleInput>[
          (comicId: 'b', title: '标题A 2'),
          (comicId: 'a', title: '标题A 1'),
          (comicId: 'c', title: '标题A 3'),
        ]);
    expect(actual.length, 1);
    expect(actual.first.seriesName, '标题A');
    expect(actual.first.entries.map((e) => e.comicId).toList(), <String>[
      'a',
      'b',
      'c',
    ]);
    expect(actual.first.entries.map((e) => e.volumeSortKey).toList(), <int>[
      1,
      2,
      3,
    ]);
  });

  test('requires at least two comics per base name', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(
      <ComicTitleInput>[(comicId: 'x', title: 'Only 1')],
    );
    expect(actual, isEmpty);
  });

  test('ignores titles without trailing digit segment', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(
      <ComicTitleInput>[
        (comicId: 'a', title: 'NoNumber'),
        (comicId: 'b', title: 'Foo 1a'),
      ],
    );
    expect(actual, isEmpty);
  });

  test('trims base name and rejects volume zero', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(
      <ComicTitleInput>[
        (comicId: 'a', title: '  标题A  0  '),
        (comicId: 'b', title: '标题A 1'),
      ],
    );
    expect(actual, isEmpty);
  });

  test('stable order for same volume uses comicId', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(
      <ComicTitleInput>[
        (comicId: 'z', title: 'S 1'),
        (comicId: 'm', title: 'S 1'),
      ],
    );
    expect(actual.length, 1);
    expect(actual.first.entries.map((e) => e.comicId).toList(), <String>[
      'm',
      'z',
    ]);
  });

  test('multiple series names sort lexically in output', () {
    final List<InferredSeriesGroup> actual = service
        .inferGroups(<ComicTitleInput>[
          (comicId: 'b', title: 'B 1'),
          (comicId: 'c', title: 'B 2'),
          (comicId: 'd', title: 'A 1'),
          (comicId: 'e', title: 'A 2'),
        ]);
    expect(actual.map((g) => g.seriesName).toList(), <String>['A', 'B']);
  });

  test('groups 前篇 before 后篇 under same series name', () {
    final List<InferredSeriesGroup> actual = service.inferGroups(
      <ComicTitleInput>[
        (comicId: 'k', title: '标题A 后篇'),
        (comicId: 'z', title: '标题A 前篇'),
      ],
    );
    expect(actual.length, 1);
    expect(actual.first.seriesName, '标题A');
    expect(actual.first.entries.map((e) => e.comicId).toList(), <String>[
      'z',
      'k',
    ]);
    expect(actual.first.entries.map((e) => e.volumeSortKey).toList(), <int>[
      1,
      2,
    ]);
  });

  test('infers 狩娘性交II alpha beta ntr and extra ordering', () {
    final InferredSeriesFromTitlesResult? actual = service
        .inferSeriesFromTitles(<String>[
          '狩娘性交II 番外編',
          '狩娘性交II β',
          '狩娘性交II α わたし…犯されて性癖に目覚めました',
          '狩娘性交II NTR編',
        ]);
    expect(actual, isNotNull);
    expect(actual!.seriesName, '狩娘性交II');
    expect(actual.indexByTitle, <String, int>{
      '狩娘性交II α わたし…犯されて性癖に目覚めました': 1,
      '狩娘性交II β': 2,
      '狩娘性交II NTR編': 3,
      '狩娘性交II 番外編': 4,
    });
  });

  test('infers わたし series with soushuuhen as volume 4', () {
    final InferredSeriesFromTitlesResult? actual = service
        .inferSeriesFromTitles(<String>[
          'わたし…変えられちゃいました',
          'わたし…変えられちゃいました。 2',
          'わたし…変えられちゃいました。 3',
          'わたし...変えられちゃいました。 ―アラサーOLがヤリチン大学生達のチ○ポにドハマリするまで― 総集編',
        ]);
    expect(actual, isNotNull);
    expect(actual!.seriesName, 'わたし…変えられちゃいました');
    expect(actual.indexByTitle, <String, int>{
      'わたし…変えられちゃいました': 1,
      'わたし…変えられちゃいました。 2': 2,
      'わたし…変えられちゃいました。 3': 3,
      'わたし...変えられちゃいました。 ―アラサーOLがヤリチン大学生達のチ○ポにドハマリするまで― 総集編': 4,
    });
  });

  test('infers bracket series with 卷 suffix titles', () {
    final InferredSeriesFromTitlesResult? actual = service
        .inferSeriesFromTitles(<String>[
          '[Kmoe][Fate／StayNight]卷04',
          '[Kmoe][Fate／StayNight]卷03',
          '[Kmoe][Fate／StayNight]卷02',
          '[Kmoe][Fate／StayNight]卷01',
        ]);
    expect(actual, isNotNull);
    expect(actual!.seriesName, 'Fate／StayNight');
    expect(actual.indexByTitle, <String, int>{
      '[Kmoe][Fate／StayNight]卷01': 1,
      '[Kmoe][Fate／StayNight]卷02': 2,
      '[Kmoe][Fate／StayNight]卷03': 3,
      '[Kmoe][Fate／StayNight]卷04': 4,
    });
  });
}
