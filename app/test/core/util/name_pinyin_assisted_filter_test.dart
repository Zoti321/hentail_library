import 'package:hentai_library/core/util/name_pinyin_assisted_filter.dart';
import 'package:test/test.dart';

void main() {
  group('nameMatchesPinyinAssistedFilter', () {
    test('empty or whitespace query matches all', () {
      expect(nameMatchesPinyinAssistedFilter('Alpha', ''), isTrue);
      expect(nameMatchesPinyinAssistedFilter('历史', '   '), isTrue);
    });

    test('matches display name case-insensitively by contains', () {
      expect(nameMatchesPinyinAssistedFilter('Alpha', '  alP  '), isTrue);
      expect(nameMatchesPinyinAssistedFilter('Beta', 'zzz'), isFalse);
    });

    test('Latin query matches tone-less full pinyin substring', () {
      expect(nameMatchesPinyinAssistedFilter('历史', 'lishi'), isTrue);
      expect(nameMatchesPinyinAssistedFilter('中国历史', 'lishi'), isTrue);
      expect(nameMatchesPinyinAssistedFilter('历史', 'guo'), isFalse);
    });

    test('Latin query matches pinyin initials substring', () {
      expect(nameMatchesPinyinAssistedFilter('历史', 'ls'), isTrue);
      expect(nameMatchesPinyinAssistedFilter('中国历史', 'zgls'), isTrue);
      expect(nameMatchesPinyinAssistedFilter('中国历史', 'ls'), isTrue);
      expect(nameMatchesPinyinAssistedFilter('中国历史', 'zs'), isFalse);
    });

    test('CJK query only matches display name substring', () {
      expect(nameMatchesPinyinAssistedFilter('历史', '史'), isTrue);
      expect(nameMatchesPinyinAssistedFilter('历史', '历x'), isFalse);
      expect(nameMatchesPinyinAssistedFilter('历史', '历ls'), isFalse);
    });

    test('pure Latin names keep contains behaviour', () {
      expect(nameMatchesPinyinAssistedFilter('CLAMP', 'cla'), isTrue);
      expect(nameMatchesPinyinAssistedFilter('CLAMP', 'xyz'), isFalse);
    });

    test('tone marks and tone digits in Latin query are ignored', () {
      expect(nameMatchesPinyinAssistedFilter('历史', 'li3shi4'), isTrue);
      expect(nameMatchesPinyinAssistedFilter('历史', 'lìshǐ'), isTrue);
    });

    test('query of only tone digits does not match all', () {
      expect(nameMatchesPinyinAssistedFilter('历史', '3'), isFalse);
      expect(nameMatchesPinyinAssistedFilter('Alpha', '4'), isFalse);
    });
  });

  group('NamePinyinIndex', () {
    test('matches same results as on-the-fly filter', () async {
      final List<String> names = <String>['历史', '中国历史', 'Alpha', 'CLAMP'];
      final NamePinyinIndex index = await buildNamePinyinIndex(names);
      for (final String name in names) {
        for (final String query in <String>[
          '',
          '   ',
          'lishi',
          'ls',
          '史',
          'cla',
          'zzz',
          'li3shi4',
          '3',
        ]) {
          expect(
            index.matches(name, query),
            nameMatchesPinyinAssistedFilter(name, query),
            reason: 'name=$name query=$query',
          );
        }
      }
    });

    test(
      'builds large lists via isolate without changing match semantics',
      () async {
        final List<String> names = <String>[
          for (int i = 0; i < kNamePinyinIndexIsolateThreshold; i++) '项$i',
          '历史',
        ];
        final NamePinyinIndex index = await buildNamePinyinIndex(names);
        expect(index.length, names.length);
        expect(index.matches('历史', 'lishi'), isTrue);
        expect(index.matches('历史', 'zzz'), isFalse);
      },
    );
  });
}
