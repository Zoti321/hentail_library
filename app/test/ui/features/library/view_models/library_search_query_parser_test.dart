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
}
