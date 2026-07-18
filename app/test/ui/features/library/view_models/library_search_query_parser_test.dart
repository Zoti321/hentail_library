import 'package:flutter_test/flutter_test.dart';
import 'package:hentai_library/ui/features/library/view_models/library_search_query_parser.dart';

void main() {
  const Set<String> tags = <String>{'战斗', '恋爱', '校园'};
  const Set<String> authors = <String>{'张三', '李四'};

  group('parseLibrarySearchQuery operators', () {
    test('A+B becomes mustInclude metadata', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '战斗+恋爱',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>()
            .having(
              (LibrarySearchMetadataQuery q) => q.mustInclude,
              'mustInclude',
              <String>{'战斗', '恋爱'},
            )
            .having(
              (LibrarySearchMetadataQuery q) => q.optionalOr,
              'optionalOr',
              isEmpty,
            )
            .having(
              (LibrarySearchMetadataQuery q) => q.mustExclude,
              'mustExclude',
              isEmpty,
            ),
      );
    });

    test('A B becomes optionalOr metadata', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '战斗 恋爱',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>().having(
          (LibrarySearchMetadataQuery q) => q.optionalOr,
          'optionalOr',
          <String>{'战斗', '恋爱'},
        ),
      );
    });

    test('A-B becomes include A and exclude B', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '战斗-恋爱',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>()
            .having(
              (LibrarySearchMetadataQuery q) => q.mustInclude,
              'mustInclude',
              <String>{'战斗'},
            )
            .having(
              (LibrarySearchMetadataQuery q) => q.mustExclude,
              'mustExclude',
              <String>{'恋爱'},
            ),
      );
    });

    test('normalizes token case against vocabulary', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        'Battle',
        knownTagNames: <String>{'battle'},
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>().having(
          (LibrarySearchMetadataQuery q) => q.mustInclude,
          'mustInclude',
          <String>{'battle'},
        ),
      );
    });
  });

  group('parseLibrarySearchQuery vocabulary routing', () {
    test('all unknown tokens fall back to keyword', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '不存在的标题词',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchKeywordQuery>().having(
          (LibrarySearchKeywordQuery q) => q.keyword,
          'keyword',
          '不存在的标题词',
        ),
      );
    });

    test('known author name routes to metadata', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '李四',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>().having(
          (LibrarySearchMetadataQuery q) => q.mustInclude,
          'mustInclude',
          <String>{'李四'},
        ),
      );
    });

    test('drops unknown tokens and keeps known metadata', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '战斗 未知词',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>().having(
          (LibrarySearchMetadataQuery q) => q.optionalOr,
          'optionalOr',
          <String>{'战斗'},
        ),
      );
    });

    test('no positive known token falls back to whole-string keyword', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '未知-战斗',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchKeywordQuery>().having(
          (LibrarySearchKeywordQuery q) => q.keyword,
          'keyword',
          '未知-战斗',
        ),
      );
    });

    test('hash prefix is not special-cased', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '#战斗',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchKeywordQuery>().having(
          (LibrarySearchKeywordQuery q) => q.keyword,
          'keyword',
          '#战斗',
        ),
      );
    });
  });

  group('parseLibrarySearchQuery quotes', () {
    test('quoted multi-word name is a single mustInclude token', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '"John Smith"',
        knownTagNames: tags,
        knownAuthorNames: <String>{'John Smith'},
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>().having(
          (LibrarySearchMetadataQuery q) => q.mustInclude,
          'mustInclude',
          <String>{'john smith'},
        ),
      );
    });

    test('quoted tokens combine with + as mustInclude', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '"战斗"+"恋爱"',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>().having(
          (LibrarySearchMetadataQuery q) => q.mustInclude,
          'mustInclude',
          <String>{'战斗', '恋爱'},
        ),
      );
    });

    test('quoted tokens combine with space as optionalOr', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '"战斗" "恋爱"',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>().having(
          (LibrarySearchMetadataQuery q) => q.optionalOr,
          'optionalOr',
          <String>{'战斗', '恋爱'},
        ),
      );
    });

    test('quoted exclude works', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '战斗-"恋爱"',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>()
            .having(
              (LibrarySearchMetadataQuery q) => q.mustInclude,
              'mustInclude',
              <String>{'战斗'},
            )
            .having(
              (LibrarySearchMetadataQuery q) => q.mustExclude,
              'mustExclude',
              <String>{'恋爱'},
            ),
      );
    });

    test('escaped quote inside quoted token', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        r'"A\"B"',
        knownTagNames: <String>{r'A"B'},
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>().having(
          (LibrarySearchMetadataQuery q) => q.mustInclude,
          'mustInclude',
          <String>{'a"b'},
        ),
      );
    });

    test('unmatched quote falls back to keyword', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '"战斗',
        knownTagNames: tags,
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchKeywordQuery>().having(
          (LibrarySearchKeywordQuery q) => q.keyword,
          'keyword',
          '"战斗',
        ),
      );
    });

    test('quoted name with hyphen stays one token', () {
      final LibrarySearchQuery query = parseLibrarySearchQuery(
        '"foo-bar"',
        knownTagNames: <String>{'foo-bar'},
        knownAuthorNames: authors,
      );

      expect(
        query,
        isA<LibrarySearchMetadataQuery>().having(
          (LibrarySearchMetadataQuery q) => q.mustInclude,
          'mustInclude',
          <String>{'foo-bar'},
        ),
      );
    });
  });

  group('formatLibrarySearchExactMetaQuery', () {
    test('wraps and escapes', () {
      expect(formatLibrarySearchExactMetaQuery('战斗'), '"战斗"');
      expect(formatLibrarySearchExactMetaQuery(r'A"B'), r'"A\"B"');
      expect(formatLibrarySearchExactMetaQuery(r'A\B'), r'"A\\B"');
    });
  });

  group('unwrapFullyQuotedLibrarySearchQuery', () {
    test('unwraps single quoted query', () {
      expect(unwrapFullyQuotedLibrarySearchQuery('"战斗"'), '战斗');
      expect(unwrapFullyQuotedLibrarySearchQuery(r'"A\"B"'), 'A"B');
    });

    test('returns null when not a single full quote', () {
      expect(unwrapFullyQuotedLibrarySearchQuery('战斗'), isNull);
      expect(unwrapFullyQuotedLibrarySearchQuery('"A"+"B"'), isNull);
      expect(unwrapFullyQuotedLibrarySearchQuery('"战斗'), isNull);
    });
  });
}
